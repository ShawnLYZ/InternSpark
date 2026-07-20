-- Tighten Phase 0 anonymity: peers/companies must NOT read author ids directly.
drop policy if exists reviews_read on public.reviews;
-- (reviews_student_own from Phase 0 remains: an author still manages their own row.)

-- Eligibility-gated create/edit (one per student+company via the unique constraint).
create or replace function public.post_review(
    p_company uuid, p_mentorship int, p_workload int, p_psych_safety int, p_comment text)
  returns public.reviews
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.reviews;
  begin
    if not exists (
      select 1 from public.applications a join public.jobs j on j.id = a.job_id
      where a.student_id = auth.uid() and j.company_id = p_company
        and a.status in ('matched','interview','offer','accepted','declined')
    ) then
      raise exception 'Not eligible to review this company';
    end if;

    insert into public.reviews (student_id, company_id, mentorship, workload, psych_safety, comment)
    values (auth.uid(), p_company, p_mentorship, p_workload, p_psych_safety, p_comment)
    on conflict (student_id, company_id) do update
      set mentorship = excluded.mentorship, workload = excluded.workload,
          psych_safety = excluded.psych_safety, comment = excluded.comment, updated_at = now()
    returning * into v_row;
    return v_row;
  end; $$;

create or replace function public.delete_review(p_company uuid)
  returns void
  language sql security definer set search_path = public
  as $$ delete from public.reviews where student_id = auth.uid() and company_id = p_company; $$;

-- Anonymized read for peers + the company: author id is never returned.
create or replace function public.company_reviews(p_company uuid)
  returns table (mentorship int, workload int, psych_safety int, comment text, created_at timestamptz)
  language sql stable security definer set search_path = public
  as $$
    select mentorship, workload, psych_safety, comment, created_at
    from public.reviews where company_id = p_company
    order by created_at desc;
  $$;

-- Aggregate (non-PII), with company name for cards. Owner-priv view → sees all reviews.
create or replace view public.company_mentorship_score as
select r.company_id, c.name as company_name, count(*) as review_count,
       round(avg(r.mentorship)::numeric, 2) as mentorship_score,
       round(avg(r.workload)::numeric, 2) as workload_score,
       round(avg(r.psych_safety)::numeric, 2) as psych_safety_score
from public.reviews r
join public.companies c on c.id = r.company_id
group by r.company_id, c.name;

grant select on public.company_mentorship_score to authenticated;
grant execute on function public.post_review(uuid, int, int, int, text) to authenticated;
grant execute on function public.delete_review(uuid) to authenticated;
grant execute on function public.company_reviews(uuid) to authenticated;
