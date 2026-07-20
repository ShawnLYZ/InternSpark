-- Phase 5: agentic skill verification.
-- student_skills becomes service-role-write-only: the verification agent is
-- the ONLY thing in the system that can grant a skill.

-- 1) Enums
create type public.curriculum_source as enum ('curated','ai_web');
create type public.certification_status as enum ('pending','approved','rejected');
create type public.skill_source as enum ('curriculum','certification');
create type public.verification_step as enum
  ('collect_input','confirm_program','certificates','preferences','summary','completed');

-- 2) Curriculum truth (fine-grained; the coarse curriculum_skills table stays untouched)
create table public.programs (
  id uuid primary key default gen_random_uuid(),
  university_id uuid not null references public.universities(id) on delete cascade,
  name text not null,
  source public.curriculum_source not null,
  created_at timestamptz not null default now()
);
create unique index programs_university_name on public.programs (university_id, lower(name));

create table public.program_skills (
  program_id uuid not null references public.programs(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  year int not null check (year between 1 and 6),
  semester int not null check (semester between 1 and 3),
  source public.curriculum_source not null,
  primary key (program_id, skill_id)
);

-- 3) The stateful workflow engine (student_id → profiles: the student_profiles
--    row does not exist yet on a first run)
create table public.verification_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  step public.verification_step not null default 'collect_input',
  input_json jsonb not null default '{}',
  findings_json jsonb not null default '{}',
  log_json jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);
create unique index verification_sessions_one_active
  on public.verification_sessions (student_id) where completed_at is null;

-- 4) Certificate uploads (files live in the existing owner-scoped 'documents' bucket)
create table public.certifications (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.verification_sessions(id) on delete set null,
  skill_id uuid references public.skills(id),
  storage_path text not null,
  original_filename text,
  status public.certification_status not null default 'pending',
  extracted_json jsonb,
  reason text,
  created_at timestamptz not null default now(),
  decided_at timestamptz
);

-- 5) Provenance + level columns
alter table public.student_profiles add column semester int check (semester between 1 and 3);
alter table public.student_skills
  add column source public.skill_source,
  add column verified_at timestamptz,
  add column evidence_json jsonb;

-- 6) RLS
alter table public.programs              enable row level security;
alter table public.program_skills        enable row level security;
alter table public.verification_sessions enable row level security;
alter table public.certifications        enable row level security;

-- Students lose direct write access to their skills; owner keeps SELECT.
-- (deck_candidates / employer_applicants are SECURITY DEFINER — unaffected.)
drop policy student_skills_own on public.student_skills;
create policy student_skills_own_read on public.student_skills
  for select using (student_id = auth.uid());

create policy programs_read on public.programs
  for select using (auth.uid() is not null);
create policy program_skills_read on public.program_skills
  for select using (auth.uid() is not null);

create policy verification_sessions_own_read on public.verification_sessions
  for select using (student_id = auth.uid());

create policy certifications_own_read on public.certifications
  for select using (student_id = auth.uid());
create policy certifications_own_insert_pending on public.certifications
  for insert with check (student_id = auth.uid() and status = 'pending');

-- 7) Explicit grants (new tables are not auto-exposed on current Supabase)
grant select on public.programs, public.program_skills, public.verification_sessions to authenticated;
grant select, insert on public.certifications to authenticated;
