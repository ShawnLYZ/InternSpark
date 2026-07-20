-- Private bucket for optional submission files (student owns; demo: text is the primary artifact).
insert into storage.buckets (id, name, public) values ('sandbox-files', 'sandbox-files', false)
on conflict (id) do nothing;
create policy sandbox_owner_write on storage.objects for insert to authenticated
  with check (bucket_id = 'sandbox-files' and owner = auth.uid());
create policy sandbox_owner_read on storage.objects for select to authenticated
  using (bucket_id = 'sandbox-files' and owner = auth.uid());

-- Employer configures the per-job task (sets has_sandbox + upserts the task).
create or replace function public.configure_sandbox(
    p_job uuid, p_source public.sandbox_source, p_prompt text, p_approved boolean)
  returns public.sandbox_tasks
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.sandbox_tasks;
  begin
    if not exists (select 1 from public.jobs j where j.id = p_job and j.company_id = public.auth_company_id()) then
      raise exception 'Not your job';
    end if;
    update public.jobs set has_sandbox = true where id = p_job;
    insert into public.sandbox_tasks (job_id, source, prompt, approved)
    values (p_job, p_source, p_prompt, p_approved)
    on conflict (job_id) do update
      set source = excluded.source, prompt = excluded.prompt, approved = excluded.approved
    returning * into v_row;
    return v_row;
  end; $$;

-- employer_swipe (Phase 1 body) now also opens a 48h sandbox row on match for enabled jobs.
create or replace function public.employer_swipe(p_application uuid, p_direction text)
  returns public.applications
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.applications; v_job uuid; v_has boolean;
  begin
    perform public._assert_owns_application(p_application);
    if p_direction = 'left' then
      update public.applications set status = 'rejected', updated_at = now()
      where id = p_application returning * into v_row;
    elsif p_direction = 'right' then
      update public.applications set status = 'matched', matched_at = now(), updated_at = now()
      where id = p_application returning * into v_row;
      -- open the parallel 48h try-out if the job has an approved sandbox task
      select a.job_id into v_job from public.applications a where a.id = p_application;
      select (j.has_sandbox and exists (select 1 from public.sandbox_tasks st where st.job_id = j.id and st.approved))
      into v_has from public.jobs j where j.id = v_job;
      if coalesce(v_has, false) then
        insert into public.sandbox_submissions (application_id, student_id, status, deadline_at)
        values (p_application, v_row.student_id, 'draft', now() + interval '48 hours')
        on conflict (application_id) do nothing;
      end if;
    else raise exception 'Invalid direction: %', p_direction;
    end if;
    return v_row;
  end; $$;

-- Student draft autosave / single submit (lapse handled by the deadline).
create or replace function public.save_sandbox_draft(p_submission uuid, p_text text, p_file_ref text)
  returns public.sandbox_submissions
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.sandbox_submissions;
  begin
    update public.sandbox_submissions
      set text = p_text, file_ref = coalesce(p_file_ref, file_ref), updated_at = now()
      where id = p_submission and student_id = auth.uid() and status = 'draft'
      returning * into v_row;
    if v_row.id is null then raise exception 'Cannot edit this submission'; end if;
    return v_row;
  end; $$;

create or replace function public.submit_sandbox(p_submission uuid)
  returns public.sandbox_submissions
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.sandbox_submissions;
  begin
    update public.sandbox_submissions
      set status = case when now() > deadline_at then 'not_submitted' else 'submitted' end,
          submitted_at = now(), updated_at = now()
      where id = p_submission and student_id = auth.uid() and status = 'draft'
      returning * into v_row;
    if v_row.id is null then raise exception 'Cannot submit this submission'; end if;
    return v_row;
  end; $$;

-- Employer verdict (informs only; never gates the next step).
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
      where id = p_submission returning * into v_row;
    return v_row;
  end; $$;

-- Student's open sandboxes (with the job title + prompt).
create or replace function public.my_sandboxes()
  returns table (id uuid, application_id uuid, status public.sandbox_submission_status,
                 text text, deadline_at timestamptz, job_title text, prompt text)
  language sql stable security definer set search_path = public
  as $$
    select s.id, s.application_id, s.status, s.text, s.deadline_at, j.title, st.prompt
    from public.sandbox_submissions s
    join public.applications a on a.id = s.application_id
    join public.jobs j on j.id = a.job_id
    left join public.sandbox_tasks st on st.job_id = j.id
    where s.student_id = auth.uid()
    order by s.deadline_at;
  $$;

-- Employer's submissions for a job (student name shown — they are matched).
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
    where j.id = p_job and j.company_id = public.auth_company_id();
  $$;

grant execute on function public.configure_sandbox(uuid, public.sandbox_source, text, boolean) to authenticated;
grant execute on function public.save_sandbox_draft(uuid, text, text) to authenticated;
grant execute on function public.submit_sandbox(uuid) to authenticated;
grant execute on function public.record_sandbox_verdict(uuid, text, text, text) to authenticated;
grant execute on function public.my_sandboxes() to authenticated;
grant execute on function public.job_sandbox_submissions(uuid) to authenticated;

-- Realtime for the live countdown / status updates.
do $$ begin
  begin alter publication supabase_realtime add table public.sandbox_submissions; exception when duplicate_object then null; end;
end $$;
