-- Open the org↔org thread for a placed student + enqueue the student disclosure.
create or replace function public.open_chat_thread(p_application uuid)
  returns public.chat_threads
  language plpgsql security definer set search_path = public
  as $$
  declare v_company uuid; v_university uuid; v_student uuid; v_row public.chat_threads;
  begin
    select a.student_id, j.company_id into v_student, v_company
    from public.applications a join public.jobs j on j.id = a.job_id
    where a.id = p_application;
    select university_id into v_university from public.student_profiles where profile_id = v_student;

    insert into public.chat_threads (company_id, university_id, student_id)
    values (v_company, v_university, v_student)
    on conflict (company_id, university_id, student_id) do nothing
    returning * into v_row;
    if v_row.id is null then
      select * into v_row from public.chat_threads
      where company_id = v_company and university_id = v_university and student_id = v_student;
    end if;

    insert into public.notifications (recipient_profile_id, type, payload_json)
    values (v_student, 'chat_disclosure',
            jsonb_build_object('company_id', v_company, 'university_id', v_university));
    return v_row;
  end; $$;

-- accept_offer now also opens the thread (Phase 1 body + this one call).
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
    return v_row;
  end; $$;

-- Send a message (participant org only).
create or replace function public.send_message(p_thread uuid, p_body text)
  returns public.chat_messages
  language plpgsql security definer set search_path = public
  as $$
  declare v_row public.chat_messages;
  begin
    if not exists (select 1 from public.chat_threads t where t.id = p_thread
      and (t.company_id = public.auth_company_id() or t.university_id = public.auth_university_id())) then
      raise exception 'Not a participant in this thread';
    end if;
    insert into public.chat_messages (thread_id, sender_profile_id, body)
    values (p_thread, auth.uid(), p_body) returning * into v_row;
    return v_row;
  end; $$;

-- List the caller org's threads with the shared student's name (RLS-safe).
create or replace function public.my_chat_threads()
  returns table (thread_id uuid, student_name text, company_name text, university_name text)
  language sql stable security definer set search_path = public
  as $$
    select t.id, sp.full_name, c.name, u.name
    from public.chat_threads t
    join public.student_profiles sp on sp.profile_id = t.student_id
    join public.companies c on c.id = t.company_id
    join public.universities u on u.id = t.university_id
    where t.company_id = public.auth_company_id() or t.university_id = public.auth_university_id();
  $$;

grant execute on function public.open_chat_thread(uuid) to authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;
grant execute on function public.my_chat_threads() to authenticated;

-- Shared Realtime pattern: stream chat messages (+ notifications for later live surfaces).
do $$
begin
  begin alter publication supabase_realtime add table public.chat_messages; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.notifications; exception when duplicate_object then null; end;
end $$;
