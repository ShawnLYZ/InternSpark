import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !serviceKey) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, serviceKey, { auth: { persistSession: false } });

const UNIVERSITY_ID = '11111111-1111-1111-1111-111111111111';
const GHOSTCORP = '22222222-2222-2222-2222-2222222222a1';
const RESPONSIVE = '22222222-2222-2222-2222-2222222222a2';
const GHOST_JOB = '33333333-3333-3333-3333-3333333333a1';
const RESP_JOB = '33333333-3333-3333-3333-3333333333a2';

const days = (n) => new Date(Date.now() - n * 24 * 3600 * 1000).toISOString();

async function ensureStudent(n) {
  const email = `student${n}@internspark.demo`;
  const created = await db.auth.admin.createUser({ email, password: 'Passw0rd!demo', email_confirm: true, user_metadata: { role: 'student' } });
  let id = created.data?.user?.id;
  if (!id) {
    const { data } = await db.auth.admin.listUsers({ page: 1, perPage: 200 });
    id = data.users.find((u) => u.email === email)?.id;
  }
  await db.from('student_profiles').upsert({
    profile_id: id, university_id: UNIVERSITY_ID, full_name: `Demo Student ${n}`,
    major: 'Computer Science', study_year: 3, location: 'Remote', remote_pref: 'remote',
    availability_start: '2026-07-01', duration_weeks: 12, salary_expectation: 2200,
    growth_statement: `Student ${n} wants to grow into shipping real products with mentorship.`,
    role_interests: ['Data'], industry_interests: ['Tech'],
  });
  return id;
}

async function main() {
  // Companies + jobs
  await db.from('companies').upsert([
    { id: GHOSTCORP, name: 'GhostCorp' },
    { id: RESPONSIVE, name: 'Responsive Inc' },
  ]);
  await db.from('jobs').upsert([
    { id: GHOST_JOB, company_id: GHOSTCORP, title: 'Backend Intern',
      description: 'Help build services.', growth_text: 'Grow into owning a service with mentorship.',
      salary_min: 2000, salary_max: 2600, location: 'Remote', remote_mode: 'remote',
      role_function: 'Software', industry: 'Tech', duration_weeks: 12, start_date: '2026-07-01' },
    { id: RESP_JOB, company_id: RESPONSIVE, title: 'Analytics Intern',
      description: 'Own dashboards.', growth_text: 'Grow from coursework to production analytics.',
      salary_min: 2100, salary_max: 2700, location: 'Remote', remote_mode: 'remote',
      role_function: 'Data', industry: 'Analytics', duration_weeks: 12, start_date: '2026-07-01' },
  ]);

  // 6 students; 6 matches at each company so both pass the >=5 min-sample gate.
  const students = [];
  for (let n = 2; n <= 7; n++) students.push(await ensureStudent(n));

  let appSeq = 100;
  const id = () => `99999999-9999-9999-9999-${String(appSeq++).padStart(12, '0')}`;

  // GhostCorp: 6 matched, backdated 8 days, NO first_response_at → ghosted.
  // Responsive Inc: 6 matched, backdated 8 days, responded within 1 day; 2 accepted (placed).
  const ghostApps = students.map((s) => ({
    id: id(), student_id: s, job_id: GHOST_JOB, status: 'matched', matched_at: days(8), first_response_at: null,
  }));
  const respApps = students.map((s, i) => ({
    id: id(), student_id: s, job_id: RESP_JOB,
    status: i < 2 ? 'accepted' : 'matched',
    matched_at: days(8), first_response_at: days(7), // responded ~1 day after match
  }));
  await db.from('applications').upsert([...ghostApps, ...respApps], { onConflict: 'student_id,job_id' });

  // Placements (for the 2 accepted at Responsive Inc) → placement_rate + ROI.
  for (const a of respApps.filter((x) => x.status === 'accepted')) {
    await db.from('internships').upsert(
      { application_id: a.id, student_id: a.student_id, company_id: RESPONSIVE, university_id: UNIVERSITY_ID },
      { onConflict: 'application_id' });
  }

  // Reviews (eligible via match) → mentorship scores on cards/leaderboard.
  await db.from('reviews').upsert(students.slice(0, 4).map((s, i) => ({
    student_id: s, company_id: i % 2 === 0 ? RESPONSIVE : GHOSTCORP,
    mentorship: i % 2 === 0 ? 5 : 2, workload: 3 + (i % 2), psych_safety: 4,
    comment: 'Verified intern review for the demo world.',
  })), { onConflict: 'student_id,company_id' });

  // A report + credit request + sandbox submission so those dashboards are alive.
  const placed = respApps.find((x) => x.status === 'accepted');
  if (placed) {
    // FIX 1: stable id so re-runs are idempotent (reports has no unique on company/student).
    await db.from('reports').upsert({
      id: '88888888-8888-8888-8888-888888880001',
      company_id: RESPONSIVE, student_id: placed.student_id, university_id: UNIVERSITY_ID,
      reliability: 5, skill: 4, communication: 5, narrative: 'Strong, reliable intern.',
    }, { onConflict: 'id' });

    const { data: intern } = await db.from('internships').select('id').eq('application_id', placed.id).maybeSingle();
    if (intern) {
      // FIX 2: stable id + onConflict:'id' (internship_id is NOT unique; dropped silent .catch).
      await db.from('credit_requests').upsert(
        { id: '77777777-7777-7777-7777-777777770001', internship_id: intern.id, university_id: UNIVERSITY_ID, status: 'pending' },
        { onConflict: 'id' });
    }

    await db.from('sandbox_tasks').upsert(
      { job_id: RESP_JOB, source: 'author', prompt: 'Summarize 3 insights from the sample data.', approved: true },
      { onConflict: 'job_id' });
    await db.from('sandbox_submissions').upsert(
      { application_id: placed.id, student_id: placed.student_id, status: 'reviewed',
        text: 'Insight 1, 2, 3.', deadline_at: days(-2), submitted_at: days(7), employer_verdict: 'strong' },
      { onConflict: 'application_id' });
  }

  console.log('Seed v2 complete: GhostCorp + Responsive Inc, 6 students, spread of matches/ghosts/placements/reviews.');
}

main().catch((e) => { console.error(e); process.exit(1); });
