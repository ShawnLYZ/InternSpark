-- 1) Deck: hard filter (mirrors core hardFilter) + per-candidate rerank inputs.
create or replace function public.deck_candidates()
  returns table (
    job_id uuid, title text, description text, growth_text text,
    company_id uuid, company_name text,
    salary_min int, salary_max int, location text, remote_mode text,
    role_function text, industry text, duration_weeks int, start_date date,
    has_sandbox boolean,
    cosine_sim double precision,
    matched_skills int, required_skills int,
    salary_expectation int, role_interests text[], industry_interests text[]
  )
  language sql stable security definer set search_path = public, extensions
  as $$
    with me as (
      select sp.profile_id, sp.growth_embedding, sp.remote_pref, sp.location,
             sp.availability_start, sp.duration_weeks, sp.salary_expectation,
             sp.role_interests, sp.industry_interests
      from public.student_profiles sp
      where sp.profile_id = auth.uid()
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
         join public.student_skills ss
           on ss.skill_id = jr.skill_id and ss.student_id = me.profile_id
       where jr.job_id = j.id)::int as matched_skills,
      (select count(*) from public.job_required_skills jr where jr.job_id = j.id)::int as required_skills,
      me.salary_expectation, me.role_interests, me.industry_interests
    from public.jobs j
    join public.companies c on c.id = j.company_id
    cross join me
    where j.published
      -- dedup: any existing application (passed/applied/…) hides the job
      and not exists (
        select 1 from public.applications a
        where a.student_id = me.profile_id and a.job_id = j.id
      )
      -- minimal hard filter: availability window + remote-mode compatibility
      and (j.start_date is null or me.availability_start is null or j.start_date >= me.availability_start)
      and (j.duration_weeks is null or me.duration_weeks is null or me.duration_weeks >= j.duration_weeks)
      and (
        me.remote_pref is null or j.remote_mode is null or me.remote_pref = 'any'
        or j.remote_mode = me.remote_pref
        or (me.remote_pref = 'remote' and j.remote_mode = 'hybrid')
      );
  $$;

grant execute on function public.deck_candidates() to authenticated;

-- 2) Student swipe + undo
create or replace function public.swipe_job(p_job uuid, p_direction text)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare
    v_status public.application_status;
    v_row public.applications;
  begin
    if p_direction = 'left' then v_status := 'passed';
    elsif p_direction = 'right' then v_status := 'applied';
    else raise exception 'Invalid swipe direction: %', p_direction;
    end if;

    insert into public.applications (student_id, job_id, status)
    values (auth.uid(), p_job, v_status)
    on conflict (student_id, job_id) do nothing
    returning * into v_row;

    if v_row.id is null then
      select * into v_row from public.applications
      where student_id = auth.uid() and job_id = p_job;
    end if;
    return v_row;
  end; $$;

create or replace function public.undo_last_swipe()
  returns uuid
  language plpgsql security definer set search_path = public
  as $$
  declare v_job uuid;
  begin
    delete from public.applications
    where id = (
      select id from public.applications
      where student_id = auth.uid() and status in ('passed','applied')
      order by created_at desc
      limit 1
    )
    returning job_id into v_job;
    return v_job;  -- null when there was nothing reversible to undo
  end; $$;

grant execute on function public.swipe_job(uuid, text) to authenticated;
grant execute on function public.undo_last_swipe() to authenticated;

-- 3) Employer swipe + post-match next steps
create or replace function public._assert_owns_application(p_application uuid)
  returns void
  language plpgsql security definer set search_path = public
  as $$
  declare v_company uuid;
  begin
    select j.company_id into v_company
    from public.applications a join public.jobs j on j.id = a.job_id
    where a.id = p_application;
    if v_company is null or v_company <> public.auth_company_id() then
      raise exception 'Not authorized for application %', p_application;
    end if;
  end; $$;

create or replace function public.employer_swipe(p_application uuid, p_direction text)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications;
  begin
    perform public._assert_owns_application(p_application);
    if p_direction = 'left' then
      update public.applications set status = 'rejected', updated_at = now()
      where id = p_application returning * into v_row;
    elsif p_direction = 'right' then
      update public.applications set status = 'matched', matched_at = now(), updated_at = now()
      where id = p_application returning * into v_row;
    else raise exception 'Invalid direction: %', p_direction;
    end if;
    return v_row;
  end; $$;

create or replace function public.request_interview(
    p_application uuid, p_email text, p_link text, p_date timestamptz)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications;
  begin
    perform public._assert_owns_application(p_application);
    update public.applications set status = 'interview', updated_at = now()
    where id = p_application returning * into v_row;
    insert into public.interview_schedules (application_id, contact_email, meeting_link, meeting_date)
    values (p_application, p_email, p_link, p_date);
    return v_row;
  end; $$;

create or replace function public.make_offer(p_application uuid)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications;
  begin
    perform public._assert_owns_application(p_application);
    update public.applications set status = 'offer', updated_at = now()
    where id = p_application returning * into v_row;
    return v_row;
  end; $$;

create or replace function public.employer_pass(p_application uuid)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications;
  begin
    perform public._assert_owns_application(p_application);
    update public.applications set status = 'employer_passed', updated_at = now()
    where id = p_application returning * into v_row;
    return v_row;
  end; $$;

grant execute on function public.employer_swipe(uuid, text) to authenticated;
grant execute on function public.request_interview(uuid, text, text, timestamptz) to authenticated;
grant execute on function public.make_offer(uuid) to authenticated;
grant execute on function public.employer_pass(uuid) to authenticated;

-- 4) Student accept / decline (accept creates the internship = placed)
create or replace function public.accept_offer(p_application uuid)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications; v_company uuid; v_university uuid;
  begin
    select a.* into v_row from public.applications a
    where a.id = p_application and a.student_id = auth.uid();
    if v_row.id is null then raise exception 'Not your application'; end if;

    update public.applications set status = 'accepted', updated_at = now()
    where id = p_application returning * into v_row;

    select j.company_id into v_company from public.jobs j where j.id = v_row.job_id;
    select sp.university_id into v_university
    from public.student_profiles sp where sp.profile_id = v_row.student_id;

    insert into public.internships (application_id, student_id, company_id, university_id)
    values (p_application, v_row.student_id, v_company, v_university)
    on conflict (application_id) do nothing;
    return v_row;
  end; $$;

create or replace function public.decline_offer(p_application uuid)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications;
  begin
    update public.applications set status = 'declined', updated_at = now()
    where id = p_application and student_id = auth.uid()
    returning * into v_row;
    if v_row.id is null then raise exception 'Not your application'; end if;
    return v_row;
  end; $$;

grant execute on function public.accept_offer(uuid) to authenticated;
grant execute on function public.decline_offer(uuid) to authenticated;

-- 5) employer_applicants v2: keep identity masking, add fit inputs + ranking.
drop function if exists public.employer_applicants(uuid);

create or replace function public.employer_applicants(p_job_id uuid)
  returns table (
    application_id uuid,
    status public.application_status,
    matched boolean,
    full_name text,
    major text,
    growth_statement text,
    required_skills text[],
    student_skills text[],
    matched_skill_count int
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
      sp.growth_statement,
      coalesce((select array_agg(s.name order by s.name)
                from public.job_required_skills jr
                join public.skills s on s.id = jr.skill_id
                where jr.job_id = a.job_id), '{}') as required_skills,
      coalesce((select array_agg(s.name order by s.name)
                from public.student_skills ss
                join public.skills s on s.id = ss.skill_id
                where ss.student_id = a.student_id), '{}') as student_skills,
      (select count(*) from public.job_required_skills jr
         join public.student_skills ss
           on ss.skill_id = jr.skill_id and ss.student_id = a.student_id
       where jr.job_id = a.job_id)::int as matched_skill_count
    from public.applications a
    join public.student_profiles sp on sp.profile_id = a.student_id
    join public.jobs j on j.id = a.job_id
    where a.job_id = p_job_id
      and j.company_id = public.auth_company_id()
      and a.status <> 'passed'
    order by matched_skill_count desc, a.created_at asc;
  $$;

grant execute on function public.employer_applicants(uuid) to authenticated;
