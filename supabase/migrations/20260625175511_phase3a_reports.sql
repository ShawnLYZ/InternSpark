-- Shared private documents bucket (reports now; credit PDFs in 3E). Owner-based.
insert into storage.buckets (id, name, public) values ('documents', 'documents', false)
on conflict (id) do nothing;

create policy documents_owner_write on storage.objects for insert to authenticated
  with check (bucket_id = 'documents' and owner = auth.uid());
create policy documents_owner_read on storage.objects for select to authenticated
  using (bucket_id = 'documents' and owner = auth.uid());

-- Students the employer may report on (matched+; identity already unlocked at match).
create or replace function public.reportable_students()
  returns table (student_id uuid, full_name text)
  language sql stable security definer set search_path = public
  as $$
    select distinct a.student_id, sp.full_name
    from public.applications a
    join public.jobs j on j.id = a.job_id
    join public.student_profiles sp on sp.profile_id = a.student_id
    where j.company_id = public.auth_company_id()
      and a.status in ('matched','interview','offer','accepted','declined');
  $$;

-- File (or update) a per-student report to the student's university.
create or replace function public.file_report(
    p_student uuid, p_reliability int, p_skill int, p_communication int,
    p_narrative text, p_pdf_path text)
  returns public.reports
  language plpgsql security definer set search_path = public
  as $$
  declare v_company uuid := public.auth_company_id(); v_university uuid; v_row public.reports;
  begin
    if v_company is null then raise exception 'Not an employer'; end if;
    if not exists (
      select 1 from public.applications a join public.jobs j on j.id = a.job_id
      where a.student_id = p_student and j.company_id = v_company
        and a.status in ('matched','interview','offer','accepted','declined')
    ) then raise exception 'No relationship with this student'; end if;

    select university_id into v_university from public.student_profiles where profile_id = p_student;

    update public.reports
      set reliability = p_reliability, skill = p_skill, communication = p_communication,
          narrative = p_narrative, pdf_path = p_pdf_path
      where company_id = v_company and student_id = p_student
      returning * into v_row;
    if v_row.id is null then
      insert into public.reports
        (company_id, student_id, university_id, reliability, skill, communication, narrative, pdf_path)
      values (v_company, p_student, v_university, p_reliability, p_skill, p_communication, p_narrative, p_pdf_path)
      returning * into v_row;
    end if;
    return v_row;
  end; $$;

grant execute on function public.reportable_students() to authenticated;
grant execute on function public.file_report(uuid, int, int, int, text, text) to authenticated;
