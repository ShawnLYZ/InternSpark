import { assertEquals } from 'jsr:@std/assert';
import {
  CONFIDENCE_THRESHOLD, certGate, extractJson, logEntry,
  matchProgram, namesMatch, normalizeCourse, normalizeName, splitBySemester,
} from './gates.ts';

Deno.test('normalizeName strips case, diacritics, punctuation, extra spaces', () => {
  assertEquals(normalizeName('  José A. RIVERA-Smith! '), 'jose a rivera smith');
});

Deno.test('normalizeCourse lowercases and collapses whitespace', () => {
  assertEquals(normalizeCourse('  Computer   Science '), 'computer science');
});

Deno.test('namesMatch: same person in different casing/punctuation matches', () => {
  assertEquals(namesMatch('Sam Rivera', 'sam RIVERA'), true);
  assertEquals(namesMatch('José Rivera', 'Jose Rivera'), true);
});

Deno.test('namesMatch: a different person (or empty) never matches', () => {
  assertEquals(namesMatch('A. Someone Else', 'Sam Rivera'), false);
  assertEquals(namesMatch('', ''), false);
});

const programs = [
  { id: 'p1', name: 'Computer Science', source: 'curated' },
  { id: 'p2', name: 'Business Analytics', source: 'ai_web' },
];

Deno.test('matchProgram: curated normalized-equal name is the instant path', () => {
  const m = matchProgram('  computer   science ', programs);
  assertEquals(m.kind, 'exact');
  if (m.kind === 'exact') assertEquals(m.program.id, 'p1');
});

Deno.test('matchProgram: ai_web exact name still requires confirmation', () => {
  const m = matchProgram('Business Analytics', programs);
  assertEquals(m.kind, 'candidates');
  if (m.kind === 'candidates') assertEquals(m.programs.map((p) => p.id), ['p2']);
});

Deno.test('matchProgram: substring either direction yields candidates', () => {
  const m = matchProgram('BSc Computer Science', programs);
  assertEquals(m.kind, 'candidates');
  if (m.kind === 'candidates') assertEquals(m.programs[0].id, 'p1');
});

Deno.test('matchProgram: no relation → none', () => {
  assertEquals(matchProgram('Culinary Arts', programs).kind, 'none');
});

const mappings = [
  { skill: 'SQL', year: 1, semester: 1 },
  { skill: 'Python', year: 1, semester: 2 },
  { skill: 'REST APIs', year: 2, semester: 1 },
  { skill: 'Java', year: 2, semester: 2 },
  { skill: 'Docker', year: 3, semester: 1 },
];

Deno.test('splitBySemester: Y2S1 gets everything up to and INCLUDING Y2S1', () => {
  const { taught, notYet } = splitBySemester(mappings, 2, 1);
  assertEquals(taught.map((m) => m.skill), ['SQL', 'Python', 'REST APIs']);
  assertEquals(notYet.map((m) => m.skill), ['Java', 'Docker']);
});

Deno.test('splitBySemester: exact boundary (year,semester) counts as taught', () => {
  const { taught } = splitBySemester([{ skill: 'X', year: 2, semester: 2 }], 2, 2);
  assertEquals(taught.length, 1);
});

const taxonomy = new Map([['python', 'skill-py'], ['java', 'skill-java']]);

Deno.test('certGate passes all gates and returns the taxonomy skill id', () => {
  const r = certGate({
    holderName: 'Sam Rivera', studentName: 'sam rivera', skillName: 'Python',
    confidence: 0.9, taxonomy, alreadyVerifiedSkillIds: new Set(),
  });
  assertEquals(r, { pass: true, skillId: 'skill-py' });
});

Deno.test('certGate rejects a name mismatch with the specific reason', () => {
  const r = certGate({
    holderName: 'A. Someone Else', studentName: 'Sam Rivera', skillName: 'Python',
    confidence: 0.9, taxonomy, alreadyVerifiedSkillIds: new Set(),
  });
  assertEquals(r.pass, false);
  if (!r.pass) assertEquals(r.reason.includes("doesn't match your registered name"), true);
});

Deno.test('certGate rejects a skill outside the taxonomy', () => {
  const r = certGate({
    holderName: 'Sam Rivera', studentName: 'Sam Rivera', skillName: 'Underwater Basket Weaving',
    confidence: 0.9, taxonomy, alreadyVerifiedSkillIds: new Set(),
  });
  assertEquals(r.pass, false);
  if (!r.pass) assertEquals(r.reason.includes('taxonomy'), true);
});

Deno.test('certGate threshold: 0.75 passes, 0.74 fails', () => {
  assertEquals(CONFIDENCE_THRESHOLD, 0.75);
  const base = {
    holderName: 'Sam Rivera', studentName: 'Sam Rivera', skillName: 'Python',
    taxonomy, alreadyVerifiedSkillIds: new Set<string>(),
  };
  assertEquals(certGate({ ...base, confidence: 0.75 }).pass, true);
  assertEquals(certGate({ ...base, confidence: 0.74 }).pass, false);
});

Deno.test('certGate rejects an already-verified skill', () => {
  const r = certGate({
    holderName: 'Sam Rivera', studentName: 'Sam Rivera', skillName: 'Python',
    confidence: 0.9, taxonomy, alreadyVerifiedSkillIds: new Set(['skill-py']),
  });
  assertEquals(r.pass, false);
  if (!r.pass) assertEquals(r.reason.includes('already verified'), true);
});

Deno.test('extractJson tolerates prose and code fences', () => {
  assertEquals(extractJson('Here you go:\n```json\n{"a": 1}\n```'), { a: 1 });
  assertEquals(extractJson('no json here'), null);
});

Deno.test('logEntry stamps an ISO time and carries kind/title/detail', () => {
  const e = logEntry('warn', 'Budget reached', 'fallback engaged');
  assertEquals(e.kind, 'warn');
  assertEquals(e.title, 'Budget reached');
  assertEquals(e.detail, 'fallback engaged');
  assertEquals(Number.isNaN(Date.parse(e.at)), false);
});
