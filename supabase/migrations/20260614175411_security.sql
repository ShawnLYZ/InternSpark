-- 1) Cross-tenant accessors (SECURITY DEFINER so policies avoid recursive RLS)
create or replace function public.auth_role()
  returns public.user_role language sql stable security definer set search_path = public
  as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.auth_company_id()
  returns uuid language sql stable security definer set search_path = public
  as $$ select company_id from public.employer_profiles where profile_id = auth.uid() $$;

create or replace function public.auth_university_id()
  returns uuid language sql stable security definer set search_path = public
  as $$ select university_id from public.university_profiles where profile_id = auth.uid() $$;

grant execute on function public.auth_role() to authenticated;
grant execute on function public.auth_company_id() to authenticated;
grant execute on function public.auth_university_id() to authenticated;

-- Auto-create a profiles row when an auth user signs up (role from metadata).
create or replace function public.handle_new_user()
  returns trigger language plpgsql security definer set search_path = public
  as $$
begin
  insert into public.profiles (id, role)
  values (
    new.id,
    coalesce(
      case when new.raw_user_meta_data->>'role' in ('student','employer','university')
           then (new.raw_user_meta_data->>'role')::public.user_role end,
      'student'
    )
  )
  on conflict (id) do nothing;
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2) Enable RLS on every table
alter table public.profiles            enable row level security;
alter table public.universities        enable row level security;
alter table public.companies           enable row level security;
alter table public.university_profiles enable row level security;
alter table public.employer_profiles   enable row level security;
alter table public.skills              enable row level security;
alter table public.student_profiles    enable row level security;
alter table public.student_skills      enable row level security;
alter table public.student_growth_tags enable row level security;
alter table public.curriculum_skills   enable row level security;
alter table public.jobs                enable row level security;
alter table public.job_required_skills enable row level security;
alter table public.job_skills_gained   enable row level security;
alter table public.job_media           enable row level security;
alter table public.applications        enable row level security;
alter table public.interview_schedules enable row level security;
alter table public.internships         enable row level security;
alter table public.reviews             enable row level security;
alter table public.reports             enable row level security;
alter table public.chat_threads        enable row level security;
alter table public.chat_messages       enable row level security;
alter table public.credit_requests     enable row level security;
alter table public.sandbox_tasks       enable row level security;
alter table public.sandbox_submissions enable row level security;
alter table public.notifications       enable row level security;
alter table public.ai_cache            enable row level security;
alter table public.ai_budget           enable row level security;

-- Identity / profiles
create policy profiles_select_own on public.profiles for select using (id = auth.uid());
create policy profiles_update_own on public.profiles for update using (id = auth.uid());

-- Public catalog (any authenticated user)
create policy universities_read on public.universities for select using (auth.uid() is not null);
create policy universities_update_own on public.universities for update using (id = public.auth_university_id());
create policy companies_read on public.companies for select using (auth.uid() is not null);
create policy companies_update_own on public.companies for update using (id = public.auth_company_id());
create policy skills_read on public.skills for select using (auth.uid() is not null);

-- Org-user link rows (owner only)
create policy university_profiles_own on public.university_profiles for all
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy employer_profiles_own on public.employer_profiles for all
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Student profile: owner full access; their university read-only; NO employer access (anonymity)
create policy student_profiles_own on public.student_profiles for all
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy student_profiles_university_read on public.student_profiles for select
  using (university_id = public.auth_university_id());

create policy student_skills_own on public.student_skills for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy student_growth_tags_own on public.student_growth_tags for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());

create policy curriculum_skills_university on public.curriculum_skills for all
  using (university_id = public.auth_university_id())
  with check (university_id = public.auth_university_id());

-- Jobs + child tables: read-all (authenticated); write by the owning employer
create policy jobs_read on public.jobs for select using (auth.uid() is not null);
create policy jobs_write_own on public.jobs for all
  using (company_id = public.auth_company_id()) with check (company_id = public.auth_company_id());

create policy job_required_skills_read on public.job_required_skills for select using (auth.uid() is not null);
create policy job_required_skills_write on public.job_required_skills for all
  using (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()))
  with check (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()));

create policy job_skills_gained_read on public.job_skills_gained for select using (auth.uid() is not null);
create policy job_skills_gained_write on public.job_skills_gained for all
  using (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()))
  with check (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()));

create policy job_media_read on public.job_media for select using (auth.uid() is not null);
create policy job_media_write on public.job_media for all
  using (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()))
  with check (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()));

-- Applications: student owns; employer of the job may read
create policy applications_student_own on public.applications for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy applications_employer_read on public.applications for select
  using (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()));

-- Interview schedules: student reads own; employer of the job writes
create policy interview_student_read on public.interview_schedules for select
  using (exists (select 1 from public.applications a where a.id = application_id and a.student_id = auth.uid()));
create policy interview_employer_write on public.interview_schedules for all
  using (exists (select 1 from public.applications a join public.jobs j on j.id = a.job_id
                 where a.id = application_id and j.company_id = public.auth_company_id()))
  with check (exists (select 1 from public.applications a join public.jobs j on j.id = a.job_id
                 where a.id = application_id and j.company_id = public.auth_company_id()));

-- Internships: visible to the three parties
create policy internships_student on public.internships for select using (student_id = auth.uid());
create policy internships_employer on public.internships for select using (company_id = public.auth_company_id());
create policy internships_university on public.internships for select using (university_id = public.auth_university_id());

-- Reviews: read-all (anonymized in the app/aggregate later); student writes own
create policy reviews_read on public.reviews for select using (auth.uid() is not null);
create policy reviews_student_own on public.reviews for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());

-- Reports: employer (author) full; their university read-only
create policy reports_employer on public.reports for all
  using (company_id = public.auth_company_id()) with check (company_id = public.auth_company_id());
create policy reports_university_read on public.reports for select
  using (university_id = public.auth_university_id());

-- Chat: org participants only (student never reads thread contents)
create policy chat_threads_company on public.chat_threads for select using (company_id = public.auth_company_id());
create policy chat_threads_university on public.chat_threads for select using (university_id = public.auth_university_id());
create policy chat_messages_read on public.chat_messages for select
  using (exists (select 1 from public.chat_threads t where t.id = thread_id
                 and (t.company_id = public.auth_company_id() or t.university_id = public.auth_university_id())));
create policy chat_messages_write on public.chat_messages for insert
  with check (sender_profile_id = auth.uid()
    and exists (select 1 from public.chat_threads t where t.id = thread_id
                and (t.company_id = public.auth_company_id() or t.university_id = public.auth_university_id())));

-- Credit requests: the owning university
create policy credit_requests_university on public.credit_requests for all
  using (university_id = public.auth_university_id())
  with check (university_id = public.auth_university_id());

-- Sandbox task config: read-all; employer of the job writes
create policy sandbox_tasks_read on public.sandbox_tasks for select using (auth.uid() is not null);
create policy sandbox_tasks_write on public.sandbox_tasks for all
  using (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()))
  with check (exists (select 1 from public.jobs j where j.id = job_id and j.company_id = public.auth_company_id()));

-- Sandbox submissions: private to student + the job's employer
create policy sandbox_sub_student on public.sandbox_submissions for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy sandbox_sub_employer_read on public.sandbox_submissions for select
  using (exists (select 1 from public.applications a join public.jobs j on j.id = a.job_id
                 where a.id = application_id and j.company_id = public.auth_company_id()));
create policy sandbox_sub_employer_update on public.sandbox_submissions for update
  using (exists (select 1 from public.applications a join public.jobs j on j.id = a.job_id
                 where a.id = application_id and j.company_id = public.auth_company_id()));

-- Notifications: recipient owns
create policy notifications_own on public.notifications for all
  using (recipient_profile_id = auth.uid()) with check (recipient_profile_id = auth.uid());

-- ai_cache / ai_budget: RLS enabled with NO policies → only the service role (Edge Function) touches them.

-- 3) State-machine transition guard (mirrors core/ ApplicationTransition; guards UPDATEs)
create or replace function public.enforce_application_transition()
  returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    if not (
      (old.status = 'applied'   and new.status in ('rejected','matched')) or
      (old.status = 'matched'   and new.status in ('interview','offer','employer_passed')) or
      (old.status = 'interview' and new.status in ('offer','employer_passed')) or
      (old.status = 'offer'     and new.status in ('accepted','declined'))
    ) then
      raise exception 'Illegal application transition: % -> %', old.status, new.status;
    end if;
  end if;
  return new;
end; $$;

create trigger trg_enforce_application_transition
  before update on public.applications
  for each row execute function public.enforce_application_transition();

-- 4) Redaction-respecting applicant read (employers never SELECT student_profiles directly).
--    Identity (full_name) is null until the application is matched. Ranking is deferred to SP1.
create or replace function public.employer_applicants(p_job_id uuid)
  returns table (
    application_id uuid,
    status public.application_status,
    matched boolean,
    full_name text,
    major text,
    growth_statement text
  )
  language sql stable security definer set search_path = public
  as $$
    select
      a.id,
      a.status,
      (a.status in ('matched','interview','offer','accepted','declined')) as matched,
      case when a.status in ('matched','interview','offer','accepted','declined')
           then sp.full_name else null end as full_name,
      sp.major,
      sp.growth_statement
    from public.applications a
    join public.student_profiles sp on sp.profile_id = a.student_id
    join public.jobs j on j.id = a.job_id
    where a.job_id = p_job_id
      and j.company_id = public.auth_company_id()
      and a.status <> 'passed';
  $$;

grant execute on function public.employer_applicants(uuid) to authenticated;
