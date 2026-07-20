import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;
function fail(msg) { console.error(`FAIL ${msg}`); ok = false; }

// accept_offer itself checks auth.uid(), so it can't run under the service role. We place a
// seeded matched student directly, then exercise the REAL open_chat_thread RPC that accept_offer
// calls, and assert it creates BOTH the org↔org thread AND the student's chat_disclosure notification.
const { data: app, error: appErr } = await db
  .from('applications').select('id, student_id, job_id').eq('status', 'matched').limit(1).maybeSingle();
if (appErr) fail(`querying matched application: ${appErr.message}`);
if (!app) {
  fail('no matched application to place (run: node supabase/seed/seed.mjs first)');
} else {
  const { data: job, error: jobErr } = await db.from('jobs').select('company_id').eq('id', app.job_id).single();
  const { data: sp, error: spErr } = await db.from('student_profiles').select('university_id').eq('profile_id', app.student_id).single();
  if (jobErr) fail(`job lookup: ${jobErr.message}`);
  if (spErr) fail(`student_profile lookup: ${spErr.message}`);

  if (ok) {
    // Clean slate so this run genuinely tests FRESH thread + disclosure creation
    // (open_chat_thread only enqueues the disclosure when the thread is newly created).
    const { error: delT } = await db.from('chat_threads').delete().eq('student_id', app.student_id);
    const { error: delN } = await db.from('notifications').delete()
      .eq('recipient_profile_id', app.student_id).eq('type', 'chat_disclosure');
    if (delT) fail(`cleanup chat_threads: ${delT.message}`);
    if (delN) fail(`cleanup notifications: ${delN.message}`);

    // Place the student through the legal funnel (matched → offer → accepted); the
    // enforce_application_transition trigger rejects a direct matched → accepted jump.
    const { error: offErr } = await db.from('applications').update({ status: 'offer' }).eq('id', app.id);
    if (offErr) fail(`offer update: ${offErr.message}`);
    const { error: updErr } = await db.from('applications').update({ status: 'accepted' }).eq('id', app.id);
    if (updErr) fail(`accept update: ${updErr.message}`);
    const { error: intErr } = await db.from('internships').upsert(
      { application_id: app.id, student_id: app.student_id, company_id: job.company_id, university_id: sp.university_id },
      { onConflict: 'application_id' });
    if (intErr) fail(`internship upsert: ${intErr.message}`);

    // Exercise the REAL function accept_offer calls.
    const { error: rpcErr } = await db.rpc('open_chat_thread', { p_application: app.id });
    if (rpcErr) fail(`open_chat_thread RPC: ${rpcErr.message}`);

    // Assert: the org↔org thread was created.
    const { data: threads, error: thErr } = await db.from('chat_threads').select('id').eq('student_id', app.student_id);
    if (thErr) fail(`chat_threads read: ${thErr.message}`);
    else if ((threads ?? []).length < 1) fail('no chat thread created');
    else console.log('OK   chat thread exists for the placed student');

    // Assert: the student disclosure was enqueued.
    const { data: notifs, error: nErr } = await db.from('notifications').select('id')
      .eq('recipient_profile_id', app.student_id).eq('type', 'chat_disclosure');
    if (nErr) fail(`notifications read: ${nErr.message}`);
    else if ((notifs ?? []).length < 1) fail('no chat_disclosure notification enqueued');
    else console.log('OK   chat_disclosure notification enqueued for the student');
  }
}

console.log(ok ? 'VERIFY PHASE3C PASS' : 'VERIFY PHASE3C FAIL');
process.exit(ok ? 0 : 1);
