-- Extensions
create extension if not exists vector with schema extensions;

-- Enums
create type public.user_role as enum ('student','employer','university');
create type public.application_status as enum
  ('passed','applied','rejected','matched','interview','offer','employer_passed','accepted','declined');
create type public.sandbox_source as enum ('author','ai');
create type public.sandbox_submission_status as enum ('draft','submitted','not_submitted','reviewed');
create type public.job_media_type as enum ('icon','video');
create type public.credit_request_status as enum ('pending','approved');

-- Identity & org
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  created_at timestamptz not null default now()
);

create table public.universities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  logo_path text,
  created_at timestamptz not null default now()
);

create table public.university_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  university_id uuid not null references public.universities(id) on delete restrict,
  title text,
  created_at timestamptz not null default now()
);

create table public.employer_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete restrict,
  title text,
  created_at timestamptz not null default now()
);

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null
);

create table public.student_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  university_id uuid not null references public.universities(id) on delete restrict,
  full_name text not null,
  photo_url text,
  major text,
  study_year int,
  grad_date date,
  location text,
  remote_pref text,
  availability_start date,
  duration_weeks int,
  salary_expectation int,
  growth_statement text,
  role_interests text[],
  industry_interests text[],
  created_at timestamptz not null default now()
);

create table public.student_skills (
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  primary key (student_id, skill_id)
);

create table public.student_growth_tags (
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  tag text not null,
  primary key (student_id, tag)
);

create table public.curriculum_skills (
  university_id uuid not null references public.universities(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  primary key (university_id, skill_id)
);

-- Jobs
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null,
  description text not null default '',
  growth_text text not null default '',
  embedding extensions.vector(384),
  salary_min int,
  salary_max int,
  location text,
  remote_mode text,
  role_function text,
  industry text,
  duration_weeks int,
  start_date date,
  has_sandbox boolean not null default false,
  published boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.job_required_skills (
  job_id uuid not null references public.jobs(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  primary key (job_id, skill_id)
);

create table public.job_skills_gained (
  job_id uuid not null references public.jobs(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  primary key (job_id, skill_id)
);

create table public.job_media (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  type public.job_media_type not null,
  storage_path text not null,
  poster_path text
);

-- Core loop
create table public.applications (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  status public.application_status not null,
  resume_json jsonb,
  resume_pdf_path text,
  matched_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, job_id)
);

create table public.interview_schedules (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  contact_email text,
  meeting_link text,
  meeting_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.internships (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique references public.applications(id) on delete cascade,
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  university_id uuid not null references public.universities(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Features
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  mentorship int not null check (mentorship between 1 and 5),
  workload int not null check (workload between 1 and 5),
  psych_safety int not null check (psych_safety between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, company_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  university_id uuid not null references public.universities(id) on delete cascade,
  reliability int check (reliability between 1 and 5),
  skill int check (skill between 1 and 5),
  communication int check (communication between 1 and 5),
  narrative text,
  pdf_path text,
  created_at timestamptz not null default now()
);

create table public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  university_id uuid not null references public.universities(id) on delete cascade,
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (company_id, university_id, student_id)
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  sender_profile_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.credit_requests (
  id uuid primary key default gen_random_uuid(),
  internship_id uuid not null references public.internships(id) on delete cascade,
  university_id uuid not null references public.universities(id) on delete cascade,
  mapping_json jsonb,
  pdf_path text,
  status public.credit_request_status not null default 'pending',
  signer_name text,
  signed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.sandbox_tasks (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.jobs(id) on delete cascade,
  source public.sandbox_source not null,
  prompt text not null default '',
  approved boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.sandbox_submissions (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique references public.applications(id) on delete cascade,
  student_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  text text,
  file_ref text,
  status public.sandbox_submission_status not null default 'draft',
  submitted_at timestamptz,
  deadline_at timestamptz,
  employer_verdict text,
  employer_notes text,
  ai_assessment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_profile_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  payload_json jsonb,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

-- AI wrapper infra
create table public.ai_cache (
  id uuid primary key default gen_random_uuid(),
  cache_key text not null unique,
  task text not null,
  response jsonb not null,
  created_at timestamptz not null default now()
);

create table public.ai_budget (
  day date primary key default current_date,
  tokens_used bigint not null default 0,
  calls int not null default 0
);
