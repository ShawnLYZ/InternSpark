-- Section 1: Record the first employer next-step time, so response/ghost math is exact.
alter table public.applications add column if not exists first_response_at timestamptz;

create or replace function public.request_interview(
    p_application uuid, p_email text, p_link text, p_date timestamptz)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications;
  begin
    perform public._assert_owns_application(p_application);
    update public.applications
      set status = 'interview', updated_at = now(), first_response_at = coalesce(first_response_at, now())
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
    update public.applications
      set status = 'offer', updated_at = now(), first_response_at = coalesce(first_response_at, now())
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
    update public.applications
      set status = 'employer_passed', updated_at = now(), first_response_at = coalesce(first_response_at, now())
    where id = p_application returning * into v_row;
    return v_row;
  end; $$;

-- Section 2: ghost_rate: ghosted / total matches over rolling 90 days, per company.
create or replace view public.ghost_rate as
with m as (
  select j.company_id, a.matched_at, a.first_response_at,
         (a.first_response_at is not null
            and a.first_response_at - a.matched_at <= interval '7 days') as responded_in_window
  from public.applications a
  join public.jobs j on j.id = a.job_id
  where a.matched_at is not null
    and a.matched_at >= now() - interval '90 days'
)
select company_id,
       count(*) as total_matches,
       count(*) filter (where not responded_in_window and now() - matched_at > interval '7 days') as ghosted,
       case when count(*) = 0 then null
            else round(
              (count(*) filter (where not responded_in_window and now() - matched_at > interval '7 days'))::numeric
              / count(*), 4)
       end as ghost_rate
from m group by company_id;

-- avg_response_time: mean(match -> first next-step); ghosted = full 7 days; pending excluded.
create or replace view public.avg_response_time as
with m as (
  select j.company_id,
    case
      when a.first_response_at is not null and a.first_response_at - a.matched_at <= interval '7 days'
        then extract(epoch from (a.first_response_at - a.matched_at))
      when now() - a.matched_at > interval '7 days'
        then extract(epoch from interval '7 days')
      else null
    end as response_secs
  from public.applications a
  join public.jobs j on j.id = a.job_id
  where a.matched_at is not null and a.matched_at >= now() - interval '90 days'
)
select company_id,
       count(*) filter (where response_secs is not null) as resolved_matches,
       avg(response_secs) filter (where response_secs is not null) as avg_response_secs
from m group by company_id;

-- Section 3: public leaderboard() -- non-PII aggregates, RLS-safe.
-- Students can read company-wide aggregates without any access to applications.
create or replace function public.leaderboard()
  returns table (
    company_id uuid, company_name text, total_matches int,
    ghost_rate numeric, avg_response_secs double precision
  )
  language sql stable security definer set search_path = public
  as $$
    select c.id, c.name,
           coalesce(gr.total_matches, 0)::int,
           gr.ghost_rate,
           art.avg_response_secs
    from public.companies c
    left join public.ghost_rate gr on gr.company_id = c.id
    left join public.avg_response_time art on art.company_id = c.id;
  $$;

grant execute on function public.leaderboard() to authenticated;
