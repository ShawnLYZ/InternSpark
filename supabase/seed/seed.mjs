import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !serviceKey) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(1);
}
const db = createClient(url, serviceKey, { auth: { persistSession: false } });

const FUNCTIONS_URL = `${url}/functions/v1/ai`;
const ANON_KEY = process.env.SUPABASE_ANON_KEY;

async function embed(text) {
  const res = await fetch(FUNCTIONS_URL, {
    method: 'POST',
    headers: { Authorization: `Bearer ${ANON_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ task: 'embed', input: text }),
  });
  if (!res.ok) throw new Error(`embed failed: ${res.status}`);
  const body = await res.json();
  return body.embedding; // 384-length array
}

const UNIVERSITY_ID = '11111111-1111-1111-1111-111111111111';
const NIMBUS_ID = '22222222-2222-2222-2222-222222222221';
const BRIGHTWAY_ID = '22222222-2222-2222-2222-222222222222';
const JOB = {
  data: '33333333-3333-3333-3333-333333330001',
  ml: '33333333-3333-3333-3333-333333330002',
  ux: '33333333-3333-3333-3333-333333330003',
  growth: '33333333-3333-3333-3333-333333330004',
  ops: '33333333-3333-3333-3333-333333330005',
};

async function ensureUser(email, password, role) {
  const created = await db.auth.admin.createUser({
    email, password, email_confirm: true, user_metadata: { role },
  });
  if (created.data?.user) return created.data.user.id;
  let page = 1;
  for (;;) {
    const { data, error } = await db.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    const found = data.users.find((u) => u.email === email);
    if (found) return found.id;
    if (data.users.length < 200) break;
    page += 1;
  }
  throw new Error(`Could not create or find user ${email}`);
}

async function main() {
  const studentId = await ensureUser('student@internspark.demo', 'Passw0rd!demo', 'student');
  const employerId = await ensureUser('employer@internspark.demo', 'Passw0rd!demo', 'employer');
  const universityId = await ensureUser('university@internspark.demo', 'Passw0rd!demo', 'university');

  await db.from('universities').upsert({ id: UNIVERSITY_ID, name: 'Springfield University' });
  await db.from('companies').upsert([
    { id: NIMBUS_ID, name: 'Nimbus Analytics' },
    { id: BRIGHTWAY_ID, name: 'Brightway Studio' },
  ]);

  await db.from('university_profiles').upsert({ profile_id: universityId, university_id: UNIVERSITY_ID, title: 'Department Head' });
  await db.from('employer_profiles').upsert({ profile_id: employerId, company_id: NIMBUS_ID, title: 'Hiring Lead' });
  await db.from('student_profiles').upsert({
    profile_id: studentId,
    university_id: UNIVERSITY_ID,
    full_name: 'Sam Rivera',
    major: 'Computer Science',
    study_year: 3,
    grad_date: '2027-06-01',
    location: 'Remote',
    remote_pref: 'remote',
    availability_start: '2026-07-01',
    duration_weeks: 12,
    salary_expectation: 2500,
    growth_statement: 'I want to grow from coursework projects into shipping real data products with mentorship.',
    role_interests: ['Data', 'Machine Learning'],
    industry_interests: ['Tech', 'Analytics'],
  });

  const { data: skills } = await db.from('skills').select('id,name');
  const skillId = (name) => {
    const s = skills.find((x) => x.name === name);
    if (!s) throw new Error(`Seed expects taxonomy skill "${name}"`);
    return s.id;
  };

  const curriculum = ['Python', 'SQL', 'Statistics', 'Data Visualization', 'Communication', 'Git'];
  await db.from('curriculum_skills').upsert(
    curriculum.map((n) => ({ university_id: UNIVERSITY_ID, skill_id: skillId(n) })),
    { onConflict: 'university_id,skill_id' },
  );

  // Phase 5: fine-grained curriculum truth + demo universities.
  const SUNWAY_ID = '11111111-1111-1111-1111-111111111112';
  await db.from('universities').upsert({ id: SUNWAY_ID, name: 'Sunway University' });
  // Sunway deliberately gets NO programs: it exercises the live grounded web-search path on stage.

  const CS_PROGRAM_ID = '77777777-7777-7777-7777-777777770001';
  await db.from('programs').upsert(
    { id: CS_PROGRAM_ID, university_id: UNIVERSITY_ID, name: 'Computer Science', source: 'curated' },
    { onConflict: 'id' },
  );
  // The pitch example: Python taught by Y2S1 (via Y1S2); Java only arrives in Y2S2.
  const programSkills = [
    ['SQL', 1, 1], ['Communication', 1, 1],
    ['Python', 1, 2], ['Git', 1, 2],
    ['REST APIs', 2, 1], ['Statistics', 2, 1],
    ['Java', 2, 2], ['Docker', 2, 2],
  ];
  await db.from('program_skills').upsert(
    programSkills.map(([n, y, s]) => ({
      program_id: CS_PROGRAM_ID, skill_id: skillId(n), year: y, semester: s, source: 'curated',
    })),
    { onConflict: 'program_id,skill_id' },
  );

  // Hero student is Y3S1 → all 8 program skills are taught → verified with
  // curriculum provenance (Profile badges render; live employer fit scores are real).
  await db.from('student_profiles').update({ semester: 1 }).eq('profile_id', studentId);
  await db.from('student_skills').upsert(
    programSkills.map(([n, y, s]) => ({
      student_id: studentId, skill_id: skillId(n), source: 'curriculum',
      verified_at: new Date().toISOString(),
      evidence_json: { program_id: CS_PROGRAM_ID, year: y, semester: s },
    })),
    { onConflict: 'student_id,skill_id' },
  );
  // Any other legacy demo rows (e.g. seed_v2 students) get an honest backfill.
  await db.from('student_skills')
    .update({ source: 'curriculum', verified_at: new Date().toISOString() })
    .is('source', null);

  await db.from('jobs').upsert([
    { id: JOB.data, company_id: NIMBUS_ID, title: 'Data Analyst Intern',
      description: 'Build dashboards and analyses for the growth team.',
      growth_text: 'Grow from spreadsheets to production analytics: own a metric end to end with weekly mentorship.',
      salary_min: 2000, salary_max: 2800, location: 'Remote', remote_mode: 'remote',
      role_function: 'Data', industry: 'Analytics', duration_weeks: 12, start_date: '2026-07-01', has_sandbox: true },
    { id: JOB.ml, company_id: NIMBUS_ID, title: 'ML Engineering Intern',
      description: 'Prototype and ship small ML features.',
      growth_text: 'Move from notebooks to deployed models; learn MLOps from a senior engineer.',
      salary_min: 2500, salary_max: 3500, location: 'Hybrid', remote_mode: 'hybrid',
      role_function: 'Machine Learning', industry: 'Tech', duration_weeks: 16, start_date: '2026-07-01', has_sandbox: false },
    { id: JOB.ux, company_id: BRIGHTWAY_ID, title: 'UX Design Intern',
      description: 'Design flows and prototypes for client apps.',
      growth_text: 'Grow from class projects to shipping real product flows with critique and mentorship.',
      salary_min: 1800, salary_max: 2400, location: 'Onsite', remote_mode: 'onsite',
      role_function: 'Design', industry: 'Creative', duration_weeks: 12, start_date: '2026-08-01', has_sandbox: true },
    { id: JOB.growth, company_id: BRIGHTWAY_ID, title: 'Growth Marketing Intern',
      description: 'Run experiments across channels.',
      growth_text: 'Learn growth experimentation: own a funnel metric and a weekly test cadence.',
      salary_min: 1800, salary_max: 2300, location: 'Remote', remote_mode: 'remote',
      role_function: 'Marketing', industry: 'Creative', duration_weeks: 10, start_date: '2026-07-15', has_sandbox: false },
    { id: JOB.ops, company_id: NIMBUS_ID, title: 'Operations Intern',
      description: 'Support operations and reporting.',
      growth_text: 'Grow into operational ownership: streamline a real process and measure the impact.',
      salary_min: 1700, salary_max: 2200, location: 'Onsite', remote_mode: 'onsite',
      role_function: 'Operations', industry: 'Analytics', duration_weeks: 12, start_date: '2026-09-01', has_sandbox: false },
  ]);

  const reqs = [
    [JOB.data, ['SQL', 'Python', 'Data Visualization']],
    [JOB.ml, ['Python', 'Machine Learning', 'PyTorch']],
    [JOB.ux, ['Figma', 'User Research', 'Prototyping']],
    [JOB.growth, ['SEO', 'A/B Testing', 'Copywriting']],
    [JOB.ops, ['Excel', 'Communication', 'Project Management']],
  ];
  const gains = [
    [JOB.data, ['dbt', 'Data Visualization', 'Statistics']],
    [JOB.ml, ['MLOps', 'PyTorch', 'Docker']],
    [JOB.ux, ['Design Systems', 'Prototyping']],
    [JOB.growth, ['A/B Testing', 'Analytics']],
    [JOB.ops, ['Project Management', 'Process Improvement']],
  ];
  await db.from('job_required_skills').upsert(
    reqs.flatMap(([job, names]) => names.map((n) => ({ job_id: job, skill_id: skillId(n) }))),
    { onConflict: 'job_id,skill_id' },
  );
  await db.from('job_skills_gained').upsert(
    gains.flatMap(([job, names]) => names.map((n) => ({ job_id: job, skill_id: skillId(n) }))),
    { onConflict: 'job_id,skill_id' },
  );

  await db.from('job_media').upsert([
    { id: '44444444-4444-4444-4444-444444440001', job_id: JOB.data, type: 'video', storage_path: 'demo/data-intern.mp4', poster_path: 'demo/data-intern.jpg' },
    { id: '44444444-4444-4444-4444-444444440002', job_id: JOB.ux, type: 'icon', storage_path: 'demo/brightway-icon.png' },
  ]);

  // NOTE: The hero student's Nimbus data-analyst application (JOB.data) is intentionally
  // NOT pre-seeded here. Pre-seeding it caused deck_candidates() to exclude the Nimbus job
  // (dedup), which blocked the stock employer@ from pairing with the student in the demo.
  // The student must swipe the Nimbus data-analyst card fresh so the golden-path click-through works.
  await db.from('applications').upsert([
    // Phase 2B: backdated 8-day unanswered match → a clean ghost for verify + the student's Matches tab.
    // Brightway (JOB.ux), NOT Nimbus — so the hero's Nimbus deck job stays un-applied and the stock golden path still pairs.
    { id: '55555555-5555-5555-5555-555555550002', student_id: studentId, job_id: JOB.ux, status: 'matched',
      matched_at: new Date(Date.now() - 8 * 24 * 3600 * 1000).toISOString() },
  ], { onConflict: 'id' });

  // Phase 2D: demo review for the hero student at Brightway (matched via JOB.ux above).
  await db.from('reviews').upsert(
    { student_id: studentId, company_id: BRIGHTWAY_ID, mentorship: 5, workload: 4, psych_safety: 5,
      comment: 'Real ownership from week one, with weekly mentorship.' },
    { onConflict: 'student_id,company_id' },
  );

  await db.from('sandbox_tasks').upsert(
    { id: '66666666-6666-6666-6666-666666660001', job_id: JOB.data, source: 'author',
      prompt: 'Review this mock weekly metrics CSV and summarize 3 insights.', approved: true },
    { onConflict: 'job_id' },
  );

  if (!ANON_KEY) {
    console.warn('SUPABASE_ANON_KEY not set — skipping embedding pass (deck will be empty).');
  } else {
    const { data: jobRows } = await db.from('jobs').select('id, title, growth_text');
    for (const j of jobRows ?? []) {
      try {
        const vec = await embed(`${j.title}. ${j.growth_text ?? ''}`);
        const { error: upErr } = await db.from('jobs').update({ embedding: vec }).eq('id', j.id);
        if (upErr) console.warn(`embed update failed for job ${j.id}: ${upErr.message}`);
      } catch (e) {
        console.warn(`embed failed for job ${j.id}: ${e.message}`);
      }
    }
    const { data: sp } = await db.from('student_profiles')
      .select('profile_id, growth_statement').eq('profile_id', studentId).maybeSingle();
    if (sp?.growth_statement) {
      try {
        const vec = await embed(sp.growth_statement);
        const { error: upErr } = await db.from('student_profiles').update({ growth_embedding: vec }).eq('profile_id', studentId);
        if (upErr) console.warn(`growth_embedding update failed: ${upErr.message}`);
      } catch (e) {
        console.warn(`hero embed failed: ${e.message}`);
      }
    }
    console.log('Embeddings populated for jobs + hero student.');
  }

  console.log('Seed complete:', { studentId, employerId, universityId });
}

main().catch((e) => { console.error(e); process.exit(1); });
