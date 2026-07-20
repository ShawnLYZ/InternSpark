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

    perform public.open_chat_thread(p_application);

    -- Enqueue a pending credit request for the university (mapping pre-filled at review time).
    insert into public.credit_requests (internship_id, university_id, status)
    select i.id, i.university_id, 'pending'
    from public.internships i
    where i.application_id = p_application
      and not exists (select 1 from public.credit_requests cr where cr.internship_id = i.id);

    return v_row;
  end; $$;

-- University reads its queue (joined names) regardless of RLS view nuances.
create or replace function public.university_credit_requests()
  returns table (
    id uuid, status public.credit_request_status, signer_name text, signed_at timestamptz,
    mapping_json jsonb, job_id uuid, job_title text, student_name text
  )
  language sql stable security definer set search_path = public
  as $$
    select cr.id, cr.status, cr.signer_name, cr.signed_at, cr.mapping_json,
           j.id, j.title, sp.full_name
    from public.credit_requests cr
    join public.internships i on i.id = cr.internship_id
    join public.applications a on a.id = i.application_id
    join public.jobs j on j.id = a.job_id
    join public.student_profiles sp on sp.profile_id = i.student_id
    where cr.university_id = public.auth_university_id()
    order by cr.created_at desc;
  $$;

-- Recorded approval: signer + timestamp + status flip.
create or replace function public.approve_credit(p_request uuid, p_signer text)
  returns public.credit_requests
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.credit_requests;
  begin
    update public.credit_requests
      set status = 'approved', signer_name = p_signer, signed_at = now()
      where id = p_request and university_id = public.auth_university_id()
      returning * into v_row;
    if v_row.id is null then raise exception 'Not your credit request'; end if;
    return v_row;
  end; $$;

grant execute on function public.university_credit_requests() to authenticated;
grant execute on function public.approve_credit(uuid, text) to authenticated;
