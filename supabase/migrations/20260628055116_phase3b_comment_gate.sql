-- Phase 3B soft comment-gate: which companies filed a report about the calling student.
-- Privacy-preserving — returns only company_id, never the report content.
create or replace function public.my_report_companies()
  returns table (company_id uuid)
  language sql stable security definer set search_path = public
  as $$ select distinct company_id from public.reports where student_id = auth.uid(); $$;

grant execute on function public.my_report_companies() to authenticated;
