import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
const anon = process.env.SUPABASE_ANON_KEY;
if (!url || !key || !anon) {
  console.error('Set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY.');
  process.exit(1);
}
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;
const pass = (m) => console.log(`OK   ${m}`);
const fail = (m) => { console.error(`FAIL ${m}`); ok = false; };

// 1) Migration landed: tables + provenance columns exist.
for (const t of ['programs', 'program_skills', 'verification_sessions', 'certifications']) {
  const { error } = await db.from(t).select('*', { head: true, count: 'exact' });
  if (error) fail(`table ${t} missing (${error.message})`); else pass(`table ${t} exists`);
}
{
  const { error } = await db.from('student_skills').select('source, verified_at, evidence_json').limit(1);
  if (error) fail(`student_skills provenance columns missing (${error.message})`);
  else pass('student_skills provenance columns exist');
}
{
  const { error } = await db.from('student_profiles').select('semester').limit(1);
  if (error) fail('student_profiles.semester missing'); else pass('student_profiles.semester exists');
}

// 2) A signed-in STUDENT cannot write student_skills (the central lockdown).
const student = createClient(url, anon);
const { data: sIn, error: sErr } = await student.auth.signInWithPassword({
  email: 'student@internspark.demo', password: 'Passw0rd!demo',
});
if (sErr) { fail(`student sign-in failed: ${sErr.message}`); }
else {
  const uid = sIn.user.id;
  const { data: probe } = await db.from('skills').select('id').eq('name', 'Kubernetes').single();
  const { error: insErr } = await student.from('student_skills')
    .insert({ student_id: uid, skill_id: probe.id, source: 'curriculum' });
  if (insErr) pass('student INSERT into student_skills blocked by RLS');
  else {
    fail('student could INSERT student_skills — LOCKDOWN BROKEN');
    await db.from('student_skills').delete().eq('student_id', uid).eq('skill_id', probe.id);
  }

  // DELETE without a write policy silently affects 0 rows — assert nothing vanished.
  const { data: before } = await db.from('student_skills').select('skill_id').eq('student_id', uid);
  await student.from('student_skills').delete().eq('student_id', uid);
  const { data: after } = await db.from('student_skills').select('skill_id').eq('student_id', uid);
  if ((before ?? []).length > 0 && (after ?? []).length === (before ?? []).length) {
    pass('student DELETE on student_skills is a no-op');
  } else if ((before ?? []).length === 0) {
    fail('hero student has no seeded skills — run seed.mjs first');
  } else {
    fail('student could DELETE student_skills — LOCKDOWN BROKEN');
  }

  // 3) Certificates: pending-only inserts.
  const { error: apprErr } = await student.from('certifications')
    .insert({ student_id: uid, storage_path: `${uid}/certs/probe.pdf`, status: 'approved' });
  if (apprErr) pass('certifications INSERT as approved blocked');
  else fail('student inserted an APPROVED certification — GATE BROKEN');
  const { data: pend, error: pendErr } = await student.from('certifications')
    .insert({ student_id: uid, storage_path: `${uid}/certs/probe.pdf`, original_filename: 'probe.pdf', status: 'pending' })
    .select().single();
  if (pendErr) fail(`pending certification insert failed: ${pendErr.message}`);
  else { pass('certifications INSERT as pending allowed'); await db.from('certifications').delete().eq('id', pend.id); }

  // 4) Sessions: owner can start; a NON-owner cannot drive it.
  const call = (tok, body) => fetch(`${url}/functions/v1/ai`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` },
    body: JSON.stringify(body),
  });
  const startRes = await call(sIn.session.access_token, { task: 'verification_start' });
  const startBody = await startRes.json();
  if (!startRes.ok || !startBody.session) fail(`verification_start failed: HTTP ${startRes.status}`);
  else {
    pass(`owner can start/resume a session (step ${startBody.session.step})`);
    try {
      const employer = createClient(url, anon);
      const { data: eIn, error: eErr } = await employer.auth.signInWithPassword({
        email: 'employer@internspark.demo', password: 'Passw0rd!demo',
      });
      if (eErr) fail(`employer sign-in failed: ${eErr.message}`);
      else {
        const adv = await call(eIn.session.access_token, {
          task: 'verification_advance', session_id: startBody.session.id, action: 'certificates_done',
        });
        if (adv.status === 403) pass('non-owner advance rejected (403)');
        else fail(`non-owner advance returned HTTP ${adv.status} (expected 403)`);
      }
    } finally {
      // MANDATORY cleanup: never leave the demo student with an active session,
      // or the mobile gate will trap them in the wizard. Runs even if the
      // employer sign-in or advance-call above throws.
      await db.from('verification_sessions').delete().eq('id', startBody.session.id);
      pass('probe session cleaned up');
    }
  }

  // 5) Curriculum catalog readable by students; Sunway seeded programless.
  const { data: progs } = await student.from('programs').select('id, name');
  if ((progs ?? []).length > 0) pass(`programs readable by students (${progs.length})`);
  else fail('programs not readable/seeded');
  const { data: sunway } = await db.from('universities').select('id')
    .eq('name', 'Sunway University').maybeSingle();
  if (!sunway) fail('Sunway University missing');
  else {
    const { data: sp } = await db.from('programs').select('id').eq('university_id', sunway.id);
    if ((sp ?? []).length === 0) pass('Sunway seeded with NO programs (live web-search path)');
    else fail('Sunway unexpectedly has programs — the live search demo would be skipped');
  }
}

console.log(ok ? 'VERIFY PHASE5 PASS' : 'VERIFY PHASE5 FAIL');
process.exit(ok ? 0 : 1);
