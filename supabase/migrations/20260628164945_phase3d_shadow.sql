-- Public bucket for day-in-the-life clips (non-sensitive; playable from the deck).
insert into storage.buckets (id, name, public) values ('shadow-videos', 'shadow-videos', true)
on conflict (id) do nothing;

create policy shadow_owner_write on storage.objects for insert to authenticated
  with check (bucket_id = 'shadow-videos' and owner = auth.uid());
create policy shadow_public_read on storage.objects for select
  using (bucket_id = 'shadow-videos');

-- deck_candidates v2: add the job's video + poster storage paths (left-joined, one video/job).
drop function if exists public.deck_candidates();

create or replace function public.deck_candidates()
  returns table (
    job_id uuid, title text, description text, growth_text text,
    company_id uuid, company_name text,
    salary_min int, salary_max int, location text, remote_mode text,
    role_function text, industry text, duration_weeks int, start_date date,
    has_sandbox boolean,
    cosine_sim double precision,
    matched_skills int, required_skills int,
    salary_expectation int, role_interests text[], industry_interests text[],
    video_path text, poster_path text
  )
  language sql stable security definer set search_path = public, extensions
  as $$
    with me as (
      select sp.profile_id, sp.growth_embedding, sp.remote_pref, sp.location,
             sp.availability_start, sp.duration_weeks, sp.salary_expectation,
             sp.role_interests, sp.industry_interests
      from public.student_profiles sp where sp.profile_id = auth.uid()
    )
    select
      j.id, j.title, j.description, j.growth_text,
      j.company_id, c.name,
      j.salary_min, j.salary_max, j.location, j.remote_mode,
      j.role_function, j.industry, j.duration_weeks, j.start_date,
      j.has_sandbox,
      case when me.growth_embedding is not null and j.embedding is not null
           then 1 - (me.growth_embedding <=> j.embedding) else 0 end as cosine_sim,
      (select count(*) from public.job_required_skills jr
         join public.student_skills ss on ss.skill_id = jr.skill_id and ss.student_id = me.profile_id
       where jr.job_id = j.id)::int as matched_skills,
      (select count(*) from public.job_required_skills jr where jr.job_id = j.id)::int as required_skills,
      me.salary_expectation, me.role_interests, me.industry_interests,
      (select jm.storage_path from public.job_media jm
        where jm.job_id = j.id and jm.type = 'video' order by jm.id limit 1) as video_path,
      (select jm.poster_path from public.job_media jm
        where jm.job_id = j.id and jm.type = 'video' order by jm.id limit 1) as poster_path
    from public.jobs j
    join public.companies c on c.id = j.company_id
    cross join me
    where j.published
      and not exists (select 1 from public.applications a where a.student_id = me.profile_id and a.job_id = j.id)
      and (j.start_date is null or me.availability_start is null or j.start_date >= me.availability_start)
      and (j.duration_weeks is null or me.duration_weeks is null or me.duration_weeks >= j.duration_weeks)
      and (
        me.remote_pref is null or j.remote_mode is null or me.remote_pref = 'any'
        or j.remote_mode = me.remote_pref
        or (me.remote_pref = 'remote' and j.remote_mode = 'hybrid')
      );
  $$;

grant execute on function public.deck_candidates() to authenticated;
