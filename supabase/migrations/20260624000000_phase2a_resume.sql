-- Private resume bucket; students own their objects.
insert into storage.buckets (id, name, public)
values ('resumes', 'resumes', false)
on conflict (id) do nothing;

create policy resumes_student_write on storage.objects for insert to authenticated
  with check (bucket_id = 'resumes' and owner = auth.uid());
create policy resumes_student_read on storage.objects for select to authenticated
  using (bucket_id = 'resumes' and owner = auth.uid());

-- Employer reads an applicant's resume JSON, name-redacted until matched
-- (mirrors core redactName). Only the job's owning employer may call it.
create or replace function public.applicant_resume(p_application uuid)
  returns jsonb
  language sql stable security definer set search_path = public
  as $$
    select case
             when a.status in ('matched','interview','offer','accepted','declined')
               then a.resume_json
             else coalesce(a.resume_json, '{}'::jsonb) || jsonb_build_object('name', 'Candidate')
           end
    from public.applications a
    join public.jobs j on j.id = a.job_id
    where a.id = p_application
      and j.company_id = public.auth_company_id();
  $$;

grant execute on function public.applicant_resume(uuid) to authenticated;
