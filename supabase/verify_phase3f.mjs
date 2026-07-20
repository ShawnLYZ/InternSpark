import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });
const DATA_JOB = '33333333-3333-3333-3333-333333330001';

let ok = true;
// Ensure the data job has an approved sandbox task (seed already adds one).
await db.from('sandbox_tasks').upsert(
  { job_id: DATA_JOB, source: 'author', prompt: 'Summarize 3 insights from the CSV.', approved: true },
  { onConflict: 'job_id' });
await db.from('jobs').update({ has_sandbox: true }).eq('id', DATA_JOB);

// Seed intentionally omits the data-job application to keep the demo deck fresh.
// Insert one (matched) for the verify if absent; ignoreDuplicates avoids triggering the
// state-machine transition trigger on subsequent runs where the row already exists.
const { data: anyStudent } = await db.from('student_profiles').select('profile_id').limit(1).maybeSingle();
if (anyStudent) {
  await db.from('applications').upsert(
    { student_id: anyStudent.profile_id, job_id: DATA_JOB, status: 'matched',
      matched_at: new Date().toISOString() },
    { onConflict: 'student_id,job_id', ignoreDuplicates: true });
}

const { data: app } = await db.from('applications').select('id, student_id').eq('job_id', DATA_JOB).limit(1).maybeSingle();
if (!app) { console.error('FAIL no application on the data job'); ok = false; }
else {
  await db.from('sandbox_submissions').upsert(
    { application_id: app.id, student_id: app.student_id, status: 'submitted',
      text: 'Insight 1, 2, 3.', deadline_at: new Date(Date.now() + 40 * 3600 * 1000).toISOString(),
      submitted_at: new Date().toISOString() },
    { onConflict: 'application_id' });
  const { data: sub } = await db.from('sandbox_submissions').select('id, status').eq('application_id', app.id).single();
  await db.from('sandbox_submissions').update({ status: 'reviewed', employer_verdict: 'strong' }).eq('id', sub.id);
  const { data: after } = await db.from('sandbox_submissions').select('status, employer_verdict').eq('id', sub.id).single();
  if (after.status !== 'reviewed') { console.error('FAIL verdict did not flip status'); ok = false; }
  else console.log(`OK   sandbox submission reviewed (verdict ${after.employer_verdict})`);
}

console.log(ok ? 'VERIFY PHASE3F PASS' : 'VERIFY PHASE3F FAIL');
process.exit(ok ? 0 : 1);
