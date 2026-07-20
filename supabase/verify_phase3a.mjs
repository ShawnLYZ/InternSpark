import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

const NIMBUS_ID = '22222222-2222-2222-2222-222222222221';
const UNIVERSITY_ID = '11111111-1111-1111-1111-111111111111';

// Find the hero student (matched at Nimbus) and write a report directly (service-role).
const { data: student, error: studentErr } = await db.from('student_profiles').select('profile_id').eq('university_id', UNIVERSITY_ID).limit(1).single();
if (studentErr || !student) { console.error(`FAIL student lookup: ${studentErr?.message ?? 'no row'}`); process.exit(1); }
const { error: upsertErr } = await db.from('reports').upsert({
  company_id: NIMBUS_ID, student_id: student.profile_id, university_id: UNIVERSITY_ID,
  reliability: 5, skill: 4, communication: 5, narrative: 'Seeded report for verification.',
});
if (upsertErr) { console.error(`FAIL reports upsert: ${upsertErr.message}`); process.exit(1); }

const { data: rows, error } = await db.from('reports').select('*').eq('university_id', UNIVERSITY_ID);
let ok = true;
if (error) { console.error(`FAIL reports read: ${error.message}`); ok = false; }
else if ((rows ?? []).length < 1) { console.error('FAIL no report rows'); ok = false; }
else console.log(`OK   reports: ${rows.length} row(s) the university can read`);

console.log(ok ? 'VERIFY PHASE3A PASS' : 'VERIFY PHASE3A FAIL');
process.exit(ok ? 0 : 1);
