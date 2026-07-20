import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(1);
}
const db = createClient(url, key, { auth: { persistSession: false } });

const tables = [
  'profiles', 'universities', 'companies', 'university_profiles', 'employer_profiles',
  'student_profiles', 'skills', 'jobs', 'job_media', 'applications', 'interview_schedules',
  'internships', 'reviews', 'reports', 'chat_threads', 'chat_messages', 'credit_requests',
  'sandbox_tasks', 'sandbox_submissions', 'notifications', 'ai_cache', 'ai_budget',
];

let ok = true;
for (const t of tables) {
  const { count, error } = await db.from(t).select('*', { count: 'exact', head: true });
  if (error) { console.error(`FAIL ${t}: ${error.message}`); ok = false; }
  else console.log(`OK   ${t}: ${count ?? 0} rows`);
}
const { count: skillCount } = await db.from('skills').select('*', { count: 'exact', head: true });
if ((skillCount ?? 0) < 40) { console.error(`FAIL taxonomy too small: ${skillCount}`); ok = false; }
else console.log(`OK   taxonomy: ${skillCount} skills`);

console.log(ok ? 'VERIFY PASS' : 'VERIFY FAIL');
process.exit(ok ? 0 : 1);
