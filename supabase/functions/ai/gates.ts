// Pure trust logic for the verification agent. No I/O, no network — every
// deterministic decision the agent makes lives here so `deno test` can pin it.

export interface LogEntryT {
  at: string;
  kind: 'user' | 'action' | 'ok' | 'warn' | 'fail';
  title: string;
  detail?: string;
}

export function logEntry(kind: LogEntryT['kind'], title: string, detail?: string): LogEntryT {
  return { at: new Date().toISOString(), kind, title, ...(detail ? { detail } : {}) };
}

/** Lowercase, strip diacritics + punctuation, collapse whitespace. */
export function normalizeName(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Deterministic identity gate: exact equality of normalized names. */
export function namesMatch(a: string, b: string): boolean {
  const na = normalizeName(a);
  return na.length > 0 && na === normalizeName(b);
}

export function normalizeCourse(s: string): string {
  return s.toLowerCase().replace(/\s+/g, ' ').trim();
}

export interface ProgramRow {
  id: string;
  name: string;
  source: string; // 'curated' | 'ai_web'
}

export type ProgramMatch =
  | { kind: 'exact'; program: ProgramRow }
  | { kind: 'candidates'; programs: ProgramRow[] }
  | { kind: 'none' };

/**
 * Curated + normalized-equal → instant path. Anything fuzzier (substring
 * either direction) or ai_web-sourced → student confirmation required.
 */
export function matchProgram(course: string, programs: ProgramRow[]): ProgramMatch {
  const c = normalizeCourse(course);
  if (c.length === 0) return { kind: 'none' };
  const exact = programs.find((p) => p.source === 'curated' && normalizeCourse(p.name) === c);
  if (exact) return { kind: 'exact', program: exact };
  const candidates = programs.filter((p) => {
    const n = normalizeCourse(p.name);
    return n === c || n.includes(c) || c.includes(n);
  });
  return candidates.length > 0 ? { kind: 'candidates', programs: candidates } : { kind: 'none' };
}

export interface SemesterMapping {
  skill: string;
  year: number;
  semester: number;
}

/** (year, semester) <= student's current level (lexicographic) → taught. */
export function splitBySemester<T extends SemesterMapping>(
  mappings: T[], year: number, semester: number,
): { taught: T[]; notYet: T[] } {
  const taught: T[] = [];
  const notYet: T[] = [];
  for (const m of mappings) {
    (m.year < year || (m.year === year && m.semester <= semester) ? taught : notYet).push(m);
  }
  return { taught, notYet };
}

export const CONFIDENCE_THRESHOLD = 0.75;

export interface CertGateInput {
  holderName: string;
  studentName: string;
  skillName: string;
  confidence: number;
  taxonomy: Map<string, string>; // lowercase skill name -> skill id
  alreadyVerifiedSkillIds: Set<string>;
}

export type CertGateResult = { pass: true; skillId: string } | { pass: false; reason: string };

/** The authoritative certificate decision. Order matters: identity first. */
export function certGate(i: CertGateInput): CertGateResult {
  if (!namesMatch(i.holderName, i.studentName)) {
    return { pass: false, reason: `The certificate names "${i.holderName}", which doesn't match your registered name.` };
  }
  const skillId = i.taxonomy.get(i.skillName.toLowerCase().trim());
  if (!skillId) {
    return { pass: false, reason: `"${i.skillName}" isn't in the InternSpark skills taxonomy.` };
  }
  if (i.confidence < CONFIDENCE_THRESHOLD) {
    return { pass: false, reason: 'Could not verify this certificate confidently (needs at least 75% confidence).' };
  }
  if (i.alreadyVerifiedSkillIds.has(skillId)) {
    return { pass: false, reason: `${i.skillName} is already verified on your profile.` };
  }
  return { pass: true, skillId };
}

/** Tolerates models that wrap JSON in prose or ```json fences. */
export function extractJson(text: string): unknown {
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
}
