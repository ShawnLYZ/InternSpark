// The verification agent: a phase-step session engine. Each client call runs
// ONE phase, appends every tool action to the session's append-only log, and
// persists state — the wizard renders this log, so the UI shows real
// orchestration, not theater. The service role here is the ONLY writer of
// student_skills in the whole system.
import { addUsage, admin, cacheKey, GEMINI_API_KEY, GEMINI_MODEL, overBudget } from './shared.ts';
import { certGate, extractJson, logEntry, matchProgram, normalizeCourse, splitBySemester, type LogEntryT } from './gates.ts';

type Json = Record<string, unknown>;

function bad(status: number, error: string): Response {
  return Response.json({ error }, { status });
}

async function callerId(req: Request): Promise<string | null> {
  const jwt = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '') ?? '';
  if (!jwt) return null;
  const { data } = await admin.auth.getUser(jwt);
  return data?.user?.id ?? null;
}

async function loadSession(id: string): Promise<Json | null> {
  const { data } = await admin.from('verification_sessions').select().eq('id', id).maybeSingle();
  return data as Json | null;
}

async function saveSession(id: string, patch: Json, entries: LogEntryT[], current: Json): Promise<Json> {
  const log = [...((current.log_json as unknown[]) ?? []), ...entries];
  const { data, error } = await admin.from('verification_sessions')
    .update({ ...patch, log_json: log, updated_at: new Date().toISOString() })
    .eq('id', id).select().single();
  if (error) throw error;
  return data as Json;
}

export async function handleVerification(task: string, req: Request, body: Json): Promise<Response> {
  const uid = await callerId(req);
  if (!uid) return bad(401, 'Unauthorized');

  if (task === 'verification_start') {
    const { data: existing } = await admin.from('verification_sessions')
      .select().eq('student_id', uid).is('completed_at', null).maybeSingle();
    if (existing) {
      if (existing.step === 'certificates') await recheckPending(uid, existing as Json);
      const fresh = await loadSession(String(existing.id));
      return Response.json({ session: fresh });
    }
    const { data: created, error } = await admin.from('verification_sessions')
      .insert({ student_id: uid, log_json: [logEntry('action', 'Verification session started')] })
      .select().single();
    if (error) return bad(500, error.message);
    return Response.json({ session: created });
  }

  // verification_advance
  const sessionId = String(body.session_id ?? '');
  const action = String(body.action ?? '');
  const session = await loadSession(sessionId);
  if (!session) return bad(404, 'Session not found');
  if (session.student_id !== uid) return bad(403, 'Not your session');
  if (session.completed_at) return bad(409, 'Session already completed');

  switch (action) {
    case 'submit_input':
      return await submitInput(uid, session, body);
    case 'confirm_program':
      return await confirmProgram(uid, session, body);
    case 'submit_certificate':
      return await submitCertificate(uid, session, body);
    case 'certificates_done': {
      if (session.step !== 'certificates') return bad(409, `Illegal action certificates_done at step ${session.step}`);
      const updated = await saveSession(sessionId, { step: 'preferences' },
        [logEntry('ok', 'Certificates step complete')], session);
      return Response.json({ session: updated });
    }
    case 'preferences_saved': {
      if (session.step !== 'preferences') return bad(409, `Illegal action preferences_saved at step ${session.step}`);
      const updated = await saveSession(sessionId, { step: 'summary' },
        [logEntry('ok', 'Preferences saved — your growth statement now drives deck ranking')], session);
      return Response.json({ session: updated });
    }
    case 'complete': {
      if (session.step !== 'summary') return bad(409, `Illegal action complete at step ${session.step}`);
      const { count } = await admin.from('student_skills')
        .select('skill_id', { count: 'exact', head: true }).eq('student_id', uid);
      const n = count ?? 0;
      const updated = await saveSession(sessionId,
        { step: 'completed', completed_at: new Date().toISOString() },
        [logEntry('ok', `Verification complete — ${n} verified skill${n === 1 ? '' : 's'} on your profile`)], session);
      return Response.json({ session: updated });
    }
    default:
      return bad(400, `Unknown action: ${action}`);
  }
}

async function submitInput(uid: string, session: Json, body: Json): Promise<Response> {
  if (session.step !== 'collect_input') return bad(409, `Illegal action submit_input at step ${session.step}`);
  const universityId = String(body.university_id ?? '');
  const course = String(body.course ?? '').trim();
  const year = Number(body.year);
  const semester = Number(body.semester);
  if (!universityId || !course || !(year >= 1 && year <= 6) || !(semester >= 1 && semester <= 3)) {
    return bad(400, 'Invalid input');
  }
  const { data: uni } = await admin.from('universities').select('name').eq('id', universityId).maybeSingle();
  if (!uni) return bad(400, 'Unknown university');

  // Create-or-update the student profile. On a first run the row does not
  // exist yet; full_name comes from the signup metadata. Never clobber an
  // existing name (seeded/demo students keep theirs).
  const { data: existingSp, error: spErr } = await admin.from('student_profiles')
    .select('full_name').eq('profile_id', uid).maybeSingle();
  if (spErr) throw spErr;
  let fullName = existingSp?.full_name as string | undefined;
  if (!fullName) {
    const { data: au } = await admin.auth.admin.getUserById(uid);
    fullName = (au?.user?.user_metadata?.full_name as string | undefined) ?? 'Student';
  }
  await admin.from('student_profiles').upsert({
    profile_id: uid, university_id: universityId, full_name: fullName,
    major: course, study_year: year, semester,
  }, { onConflict: 'profile_id' });

  const entries: LogEntryT[] = [
    logEntry('user', `You: ${course} at ${uni.name}, Year ${year} Semester ${semester}`),
    logEntry('action', 'Checking the InternSpark curriculum database…'),
  ];
  const input_json = { university_id: universityId, university_name: uni.name, course, year, semester };

  const { data: programs } = await admin.from('programs')
    .select('id, name, source').eq('university_id', universityId);
  const match = matchProgram(course, (programs ?? []) as { id: string; name: string; source: string }[]);

  if (match.kind === 'exact') {
    entries.push(logEntry('ok', `Found curated program "${match.program.name}" — verifying instantly, no web search needed`));
    const derived = await deriveAndWrite(uid, match.program.id, year, semester, entries);
    const updated = await saveSession(String(session.id), {
      step: 'certificates', input_json,
      findings_json: {
        mode: 'db', program_id: match.program.id, program_name: match.program.name,
        candidates: [], lookup_failed: false, ...derived,
      },
    }, entries, session);
    return Response.json({ session: updated });
  }

  if (match.kind === 'candidates') {
    entries.push(logEntry('ok', `Found ${match.programs.length} possible program${match.programs.length === 1 ? '' : 's'} — please confirm yours`));
    const updated = await saveSession(String(session.id), {
      step: 'confirm_program', input_json,
      findings_json: { mode: 'db', candidates: match.programs, lookup_failed: false, taught: [], not_yet: [] },
    }, entries, session);
    return Response.json({ session: updated });
  }

  entries.push(logEntry('action', `Not in our database — searching ${uni.name}'s public course pages…`));
  return await webLookup(session, input_json, uni.name, course, entries);
}

async function confirmProgram(uid: string, session: Json, body: Json): Promise<Response> {
  if (session.step !== 'confirm_program') return bad(409, `Illegal action confirm_program at step ${session.step}`);
  const accept = Boolean(body.accept);
  const input = session.input_json as { university_id: string; course: string; year: number; semester: number };

  if (!accept) {
    const updated = await saveSession(String(session.id), { step: 'collect_input' }, [
      logEntry('user', "You: that's not my program"),
      logEntry('action', 'No problem — adjust your course name and I will look again'),
    ], session);
    return Response.json({ session: updated });
  }

  const findings = (session.findings_json ?? {}) as Json;
  const entries: LogEntryT[] = [];
  let programId = body.program_id ? String(body.program_id) : null;
  let programName = '';

  if (programId) {
    const { data: p } = await admin.from('programs').select('id, name').eq('id', programId).maybeSingle();
    if (!p) return bad(400, 'Unknown program');
    programName = p.name as string;
    entries.push(logEntry('user', `You confirmed: ${programName}`));
  } else {
    // Web-derived: persist the confirmed mappings for reuse by future students
    // from this university. Unique index is on (university_id, lower(name)) —
    // an expression — so check-then-insert instead of upsert.
    const web = findings.web as {
      program_name?: string;
      mappings?: { skill: string; skill_id: string; year: number; semester: number }[];
    } | undefined;
    if (!web?.program_name || !web.mappings?.length) return bad(400, 'Nothing to confirm');
    programName = web.program_name;
    entries.push(logEntry('user', `You confirmed: ${programName}`));

    const { data: prior } = await admin.from('programs').select('id')
      .eq('university_id', input.university_id).ilike('name', programName).maybeSingle();
    if (prior) {
      programId = String(prior.id);
    } else {
      const { data: created, error } = await admin.from('programs')
        .insert({ university_id: input.university_id, name: programName, source: 'ai_web' })
        .select('id').single();
      if (error) {
        const { data: again } = await admin.from('programs').select('id')
          .eq('university_id', input.university_id).ilike('name', programName).single();
        if (!again) return bad(500, 'Program lookup race unresolved');
        programId = String(again.id);
      } else {
        programId = String(created.id);
      }
    }
    await admin.from('program_skills').upsert(
      web.mappings.map((m) => ({
        program_id: programId, skill_id: m.skill_id, year: m.year, semester: m.semester, source: 'ai_web',
      })),
      { onConflict: 'program_id,skill_id' },
    );
    entries.push(logEntry('ok', `Saved ${web.mappings.length} curriculum mappings — future ${programName} students verify instantly`));
  }

  const derived = await deriveAndWrite(uid, programId!, Number(input.year), Number(input.semester), entries);
  const updated = await saveSession(String(session.id), {
    step: 'certificates',
    findings_json: {
      mode: findings.web ? 'web' : 'db', program_id: programId, program_name: programName,
      candidates: [], lookup_failed: false, ...derived,
    },
  }, entries, session);
  return Response.json({ session: updated });
}

/**
 * The deterministic semester split + the ONLY skill write in the system.
 * Re-runs replace curriculum + legacy (null-source) rows; certification rows
 * persist — they were independently proven.
 */
async function deriveAndWrite(
  uid: string, programId: string, year: number, semester: number, entries: LogEntryT[],
): Promise<{ taught: Json[]; not_yet: Json[] }> {
  const { data: rows, error: psErr } = await admin.from('program_skills')
    .select('skill_id, year, semester, skills(name)').eq('program_id', programId);
  if (psErr) throw psErr;
  const mappings = (rows ?? []).map((r) => ({
    skill: ((r.skills as { name?: string } | null)?.name) ?? '',
    skillId: String(r.skill_id),
    year: Number(r.year),
    semester: Number(r.semester),
  }));
  const { taught, notYet } = splitBySemester(mappings, year, semester);

  const { error: delErr } = await admin.from('student_skills').delete().eq('student_id', uid).or('source.eq.curriculum,source.is.null');
  if (delErr) throw delErr;
  if (taught.length > 0) {
    const { error: insErr } = await admin.from('student_skills').insert(taught.map((t) => ({
      student_id: uid, skill_id: t.skillId, source: 'curriculum',
      verified_at: new Date().toISOString(),
      evidence_json: { program_id: programId, year: t.year, semester: t.semester },
    })));
    if (insErr) throw insErr;
    for (const t of taught) entries.push(logEntry('ok', `Verified ${t.skill} — taught in Y${t.year}S${t.semester}`));
  } else {
    entries.push(logEntry('ok', 'No skills taught yet by your current semester — your profile starts honestly empty'));
  }
  for (const n of notYet) {
    entries.push(logEntry('action', `${n.skill} isn't taught until Y${n.year}S${n.semester} — upload a certificate if you already have it`));
  }
  return {
    taught: taught.map((t) => ({ skill: t.skill, skill_id: t.skillId, year: t.year, semester: t.semester })),
    not_yet: notYet.map((n) => ({ skill: n.skill, skill_id: n.skillId, year: n.year, semester: n.semester })),
  };
}

/**
 * One budget-respecting Gemini call. Grounding (google_search tool) cannot be
 * combined with responseSchema in a single call — callers chain two calls.
 */
async function gemini(
  parts: unknown[], opts: { tools?: unknown[]; config?: Json } = {},
): Promise<{ ok: boolean; text: string }> {
  if (await overBudget()) return { ok: false, text: '' };
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{ parts }],
        ...(opts.tools ? { tools: opts.tools } : {}),
        ...(opts.config ? { generationConfig: opts.config } : {}),
      }),
    },
  );
  if (!res.ok) return { ok: false, text: '' };
  const data = await res.json();
  const text = ((data?.candidates?.[0]?.content?.parts ?? []) as { text?: string }[])
    .map((p) => p.text ?? '').join('');
  await addUsage(text.length);
  return { ok: text.length > 0, text };
}

async function taxonomyMap(): Promise<Map<string, { id: string; name: string }>> {
  const { data, error } = await admin.from('skills').select('id, name');
  if (error) throw error;
  return new Map(((data ?? []) as { id: string; name: string }[])
    .map((s) => [s.name.toLowerCase(), { id: s.id, name: s.name }]));
}

interface WebFindings {
  program_name?: string;
  confidence?: number;
  source_urls?: string[];
  mappings?: { skill: string; year: number; semester: number }[];
}

async function webLookup(
  session: Json, input_json: Json, universityName: string, course: string, entries: LogEntryT[],
): Promise<Response> {
  const universityId = String((input_json as { university_id: string }).university_id);
  const key = await cacheKey('curriculum_lookup', `${universityId}::${normalizeCourse(course)}`);
  const { data: cached } = await admin.from('ai_cache').select('response').eq('cache_key', key).maybeSingle();

  let structured: WebFindings | null = null;
  if (cached) {
    structured = cached.response as WebFindings;
    entries.push(logEntry('ok', 'Found a previous lookup for this program (cached) — no web search needed'));
  } else {
    const grounded = await gemini(
      [{ text: `Find the official public curriculum/syllabus for the degree program "${course}" at ${universityName}. ` +
               `List, per year of study and per semester, the concrete skills, tools, and technologies taught ` +
               `(course/module names plus the skills they teach). Cite the source URLs you used.` }],
      { tools: [{ google_search: {} }] },
    );
    if (!grounded.ok) return await lookupFailed(session, input_json, entries, 'web search unavailable right now (budget or upstream error)');
    entries.push(logEntry('ok', `Read ${universityName}'s public course pages`));
    entries.push(logEntry('action', 'Mapping findings to the InternSpark skills taxonomy…'));

    const taxonomy = await taxonomyMap();
    const names = [...taxonomy.values()].map((t) => t.name).join(', ');
    const schema = {
      type: 'object',
      properties: {
        program_name: { type: 'string' },
        confidence: { type: 'number' },
        source_urls: { type: 'array', items: { type: 'string' } },
        mappings: {
          type: 'array',
          items: {
            type: 'object',
            properties: { skill: { type: 'string' }, year: { type: 'integer' }, semester: { type: 'integer' } },
            required: ['skill', 'year', 'semester'],
          },
        },
      },
      required: ['program_name', 'mappings', 'confidence'],
    };
    const mapped = await gemini(
      [{ text: `From the curriculum findings below, output JSON mapping what is taught to skill names taken ` +
               `EXACTLY from this list (use only names from the list; omit everything else): ${names}.\n\n` +
               `Findings:\n${grounded.text}` }],
      { config: { responseMimeType: 'application/json', responseSchema: schema } },
    );
    if (!mapped.ok) return await lookupFailed(session, input_json, entries, 'skill mapping unavailable right now');
    structured = extractJson(mapped.text) as WebFindings | null;
    if (!structured?.mappings?.length) return await lookupFailed(session, input_json, entries, 'no usable curriculum information found');
    await admin.from('ai_cache').upsert(
      { cache_key: key, task: 'curriculum_lookup', response: structured },
      { onConflict: 'cache_key', ignoreDuplicates: true },
    );
  }

  // Server-side re-validation: drop anything the model invented, whatever it said.
  const taxonomy = await taxonomyMap();
  const valid = (structured.mappings ?? []).flatMap((m) => {
    const t = taxonomy.get(m.skill.toLowerCase().trim());
    return t ? [{ skill: t.name, skill_id: t.id, year: Number(m.year), semester: Number(m.semester) }] : [];
  });
  const dropped = (structured.mappings ?? []).length - valid.length;
  if (dropped > 0) entries.push(logEntry('warn', `Dropped ${dropped} finding${dropped === 1 ? '' : 's'} not in the skills taxonomy`));
  if (valid.length === 0) return await lookupFailed(session, input_json, entries, 'nothing mapped to the skills taxonomy');

  const programName = structured.program_name ?? course;
  entries.push(logEntry('ok', `Mapped ${valid.length} skills from "${programName}" — please confirm this is your program`));
  const updated = await saveSession(String(session.id), {
    step: 'confirm_program', input_json,
    findings_json: {
      mode: 'web',
      candidates: [{ id: null, name: programName, source: 'ai_web' }],
      web: { program_name: programName, mappings: valid, confidence: structured.confidence ?? 0, source_urls: structured.source_urls ?? [] },
      lookup_failed: false, taught: [], not_yet: [],
    },
  }, entries, session);
  return Response.json({ session: updated });
}

async function lookupFailed(
  session: Json, input_json: Json, entries: LogEntryT[], why: string,
): Promise<Response> {
  entries.push(logEntry('fail', `Curriculum lookup failed — ${why}`));
  entries.push(logEntry('warn', 'You can still verify skills with certificates now, and retry the lookup later from "Update profile"'));
  const updated = await saveSession(String(session.id), {
    step: 'certificates', input_json,
    findings_json: { mode: 'cert_only', candidates: [], lookup_failed: true, taught: [], not_yet: [] },
  }, entries, session);
  return Response.json({ session: updated });
}

const MAX_CERT_BYTES = 15 * 1024 * 1024;

function mimeFor(name: string): string | null {
  const ext = name.toLowerCase().split('.').pop() ?? '';
  return ({ pdf: 'application/pdf', png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg' } as Record<string, string>)[ext] ?? null;
}

function toBase64(bytes: Uint8Array): string {
  let out = '';
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    out += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(out);
}

async function submitCertificate(uid: string, session: Json, body: Json): Promise<Response> {
  if (session.step !== 'certificates') return bad(409, `Illegal action submit_certificate at step ${session.step}`);
  const certId = String(body.certification_id ?? '');
  const { data: cert } = await admin.from('certifications').select().eq('id', certId).maybeSingle();
  if (!cert || cert.student_id !== uid) return bad(403, 'Not your certificate');
  if (cert.status !== 'pending') return bad(409, `Certificate already ${cert.status}`);

  const entries: LogEntryT[] = [logEntry('action', `Reading certificate "${cert.original_filename ?? 'upload'}"…`)];
  const decided = await verifyCertificate(uid, cert as Json, entries);
  const updated = await saveSession(String(session.id), {}, entries, session);
  return Response.json({ session: updated, certification: decided });
}

/**
 * Vision extraction + the deterministic gates. AI unavailable → the row STAYS
 * pending (narrated as a warn) and is re-checked on the next run — an outage
 * never loses an upload and never grants a skill.
 */
async function verifyCertificate(uid: string, cert: Json, entries: LogEntryT[]): Promise<Json> {
  const decide = async (status: 'approved' | 'rejected', patch: Json, entry: LogEntryT): Promise<Json> => {
    const { data, error } = await admin.from('certifications')
      .update({ status, decided_at: new Date().toISOString(), ...patch })
      .eq('id', cert.id).select().single();
    if (error) throw error;
    entries.push(entry);
    return data as Json;
  };

  const mime = mimeFor(String(cert.original_filename ?? cert.storage_path));
  if (!mime) {
    return await decide('rejected', { reason: 'Unsupported file type — upload a PDF, PNG, or JPG.' },
      logEntry('fail', 'Certificate rejected: unsupported file type'));
  }

  const { data: blob, error: dlErr } = await admin.storage.from('documents').download(String(cert.storage_path));
  if (dlErr || !blob) {
    entries.push(logEntry('warn', 'Could not read the upload right now — kept as pending, will re-check on your next run'));
    return cert;
  }
  const bytes = new Uint8Array(await blob.arrayBuffer());
  if (bytes.length > MAX_CERT_BYTES) {
    return await decide('rejected', { reason: 'File too large to verify (max 15 MB).' },
      logEntry('fail', 'Certificate rejected: file too large'));
  }

  const taxonomy = await taxonomyMap();
  const names = [...taxonomy.values()].map((t) => t.name).join(', ');
  const schema = {
    type: 'object',
    properties: {
      holder_name: { type: 'string' },
      credential_title: { type: 'string' },
      issuer: { type: 'string' },
      issue_date: { type: 'string' },
      skill: { type: 'string' },
      confidence: { type: 'number' },
    },
    required: ['holder_name', 'credential_title', 'skill', 'confidence'],
  };
  const vision = await gemini([
    { inlineData: { mimeType: mime, data: toBase64(bytes) } },
    { text: `Extract from this certificate document: the holder's full name, the credential title, the issuing ` +
            `organization, the issue date (ISO format if possible), the single best-matching skill chosen EXACTLY ` +
            `from this list: ${names}, and your confidence (0-1) that this is a genuine skill certificate for that skill.` },
  ], { config: { responseMimeType: 'application/json', responseSchema: schema } });
  if (!vision.ok) {
    entries.push(logEntry('warn', 'AI unavailable (budget or upstream error) — certificate kept as pending, will re-check on your next run'));
    return cert;
  }
  const ex = extractJson(vision.text) as {
    holder_name?: string; credential_title?: string; issuer?: string;
    issue_date?: string; skill?: string; confidence?: number;
  } | null;
  if (!ex) {
    entries.push(logEntry('warn', 'Could not parse the reading — certificate kept as pending, will re-check on your next run'));
    return cert;
  }

  const { data: sp, error: spErr } = await admin.from('student_profiles').select('full_name').eq('profile_id', uid).single();
  if (spErr) throw spErr;
  const { data: existing, error: exErr } = await admin.from('student_skills').select('skill_id').eq('student_id', uid);
  if (exErr) throw exErr;
  const gate = certGate({
    holderName: ex.holder_name ?? '',
    studentName: (sp?.full_name as string | undefined) ?? '',
    skillName: ex.skill ?? '',
    confidence: ex.confidence ?? 0,
    taxonomy: new Map([...taxonomy].map(([k, v]) => [k, v.id])),
    alreadyVerifiedSkillIds: new Set(((existing ?? []) as { skill_id: string }[]).map((r) => r.skill_id)),
  });
  const extracted = {
    holder_name: ex.holder_name, credential_title: ex.credential_title,
    issuer: ex.issuer, issue_date: ex.issue_date, skill: ex.skill, confidence: ex.confidence,
  };

  if (!gate.pass) {
    return await decide('rejected', { extracted_json: extracted, reason: gate.reason },
      logEntry('fail', `Certificate rejected: ${gate.reason}`));
  }

  const { error: insErr } = await admin.from('student_skills').insert({
    student_id: uid, skill_id: gate.skillId, source: 'certification',
    verified_at: new Date().toISOString(),
    evidence_json: { certification_id: cert.id, issuer: ex.issuer ?? '', issue_date: ex.issue_date ?? '' },
  });
  if (insErr) throw insErr;
  const skillName = taxonomy.get((ex.skill ?? '').toLowerCase().trim())?.name ?? ex.skill;
  return await decide('approved', {
    extracted_json: extracted, skill_id: gate.skillId,
    reason: `Verified: ${ex.credential_title ?? 'certificate'} from ${ex.issuer ?? 'the issuer'}`,
  }, logEntry('ok', `Verified ${skillName} from your certificate — added with certification provenance`));
}

/** Outage recovery: on resume at the certificates step, retry anything pending. */
async function recheckPending(uid: string, session: Json): Promise<void> {
  const { data: pending } = await admin.from('certifications')
    .select().eq('student_id', uid).eq('status', 'pending');
  if (!pending?.length) return;
  const entries: LogEntryT[] = [
    logEntry('action', `Re-checking ${pending.length} pending certificate${pending.length === 1 ? '' : 's'} from last time…`),
  ];
  for (const c of pending) {
    await verifyCertificate(uid, c as Json, entries);
  }
  await saveSession(String(session.id), {}, entries, session);
}
