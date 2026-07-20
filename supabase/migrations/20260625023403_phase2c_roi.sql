-- market_demand (global, non-PII): skill frequency across required + gained skills,
-- weighted by employer matches. Runs as owner so the match counts are complete.
create or replace view public.market_demand as
with skill_jobs as (
  select s.id as skill_id, s.name as skill_name, js.job_id
  from public.skills s
  join (
    select job_id, skill_id from public.job_required_skills
    union
    select job_id, skill_id from public.job_skills_gained
  ) js on js.skill_id = s.id
),
match_counts as (
  select job_id, count(*) as match_count
  from public.applications
  where status in ('matched','interview','offer','accepted','declined')
  group by job_id
)
select sj.skill_id, sj.skill_name,
       sum(1 + coalesce(mc.match_count, 0))::numeric as demand
from skill_jobs sj
left join match_counts mc on mc.job_id = sj.job_id
group by sj.skill_id, sj.skill_name;

grant select on public.market_demand to authenticated;

-- placement_rate (per university; used by the definer helper + service-role verify).
create or replace view public.placement_rate as
select sp.university_id,
       count(distinct sp.profile_id) as total_students,
       count(distinct i.student_id) as placed_students,
       case when count(distinct sp.profile_id) = 0 then 0
            else round(count(distinct i.student_id)::numeric / count(distinct sp.profile_id), 4) end as placement_rate
from public.student_profiles sp
left join public.internships i on i.student_id = sp.profile_id
group by sp.university_id;

-- The caller-university's placement rate (RLS-safe wrapper).
create or replace function public.university_placement_rate()
  returns numeric language sql stable security definer set search_path = public
  as $$
    select coalesce(placement_rate, 0)
    from public.placement_rate
    where university_id = public.auth_university_id();
  $$;

-- curriculum_gap (implements roi_demand_vs_curriculum): in-demand skills the
-- caller-university does not teach, in demand order.
create or replace function public.curriculum_gap()
  returns table (skill_id uuid, skill_name text, demand numeric)
  language sql stable security definer set search_path = public
  as $$
    select md.skill_id, md.skill_name, md.demand
    from public.market_demand md
    where not exists (
      select 1 from public.curriculum_skills cs
      where cs.university_id = public.auth_university_id() and cs.skill_id = md.skill_id)
    order by md.demand desc;
  $$;

grant execute on function public.university_placement_rate() to authenticated;
grant execute on function public.curriculum_gap() to authenticated;
