-- Phase 3C hardening (review finding): open_chat_thread is internal-only, and the
-- chat_disclosure notification fires only when the thread is freshly created.

-- Re-define so the disclosure notification is enqueued ONLY on fresh thread creation
-- (idempotent re-calls no longer insert duplicate disclosures).
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
    else
      insert into public.notifications (recipient_profile_id, type, payload_json)
      values (v_student, 'chat_disclosure',
              jsonb_build_object('company_id', v_company, 'university_id', v_university));
    end if;
    return v_row;
  end; $$;

-- open_chat_thread is called only INTERNALLY by accept_offer (SECURITY DEFINER → runs as owner,
-- needs no grant). It has no caller/status guard, so no client role may call it directly
-- (spec §3.3: a thread exists only for placed shared students). service_role (trusted backend:
-- the Phase 3C verify script) may still call it.
revoke execute on function public.open_chat_thread(uuid) from public, anon, authenticated;
grant execute on function public.open_chat_thread(uuid) to service_role;
