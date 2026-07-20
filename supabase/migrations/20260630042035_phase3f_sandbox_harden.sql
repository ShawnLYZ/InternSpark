-- Phase 3F hardening (final-branch-review finding): align SQL with the Dart sandbox
-- state machine (draft → submitted → reviewed).
--
-- 1. record_sandbox_verdict: guard UPDATE to status IN ('submitted','reviewed') only
--    (forbids draft/not_submitted → reviewed; allows idempotent re-review).
-- 2. job_sandbox_submissions: exclude draft rows from the employer list
--    (employers should grade only submitted/reviewed/not_submitted work).

-- Employer verdict — only callable on submitted or already-reviewed submissions.
create or replace function public.record_sandbox_verdict(
    p_submission uuid, p_verdict text, p_notes text, p_ai_assessment text)
  returns public.sandbox_submissions
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.sandbox_submissions;
  begin
    if not exists (
      select 1 from public.sandbox_submissions s
      join public.applications a on a.id = s.application_id
      join public.jobs j on j.id = a.job_id
      where s.id = p_submission and j.company_id = public.auth_company_id()
    ) then raise exception 'Not your submission'; end if;
    update public.sandbox_submissions
      set employer_verdict = p_verdict, employer_notes = p_notes,
          ai_assessment = coalesce(p_ai_assessment, ai_assessment),
          status = 'reviewed', updated_at = now()
      where id = p_submission and status in ('submitted','reviewed') returning * into v_row;
    if v_row.id is null then raise exception 'Cannot record verdict — submission not submitted'; end if;
    return v_row;
  end; $$;

-- Employer submission list — hide in-progress student drafts.
create or replace function public.job_sandbox_submissions(p_job uuid)
  returns table (id uuid, status public.sandbox_submission_status, text text, file_ref text,
                 employer_verdict text, employer_notes text, ai_assessment text, student_name text)
  language sql stable security definer set search_path = public
  as $$
    select s.id, s.status, s.text, s.file_ref, s.employer_verdict, s.employer_notes, s.ai_assessment, sp.full_name
    from public.sandbox_submissions s
    join public.applications a on a.id = s.application_id
    join public.jobs j on j.id = a.job_id
    join public.student_profiles sp on sp.profile_id = s.student_id
    where j.id = p_job and j.company_id = public.auth_company_id()
      and s.status <> 'draft';
  $$;
