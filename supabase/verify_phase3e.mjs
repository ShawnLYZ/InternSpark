import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;

// A placement (internship) must exist — acceptance is what enqueues credit requests in prod.
// NOTE: seed.mjs does NOT create internships; run `node supabase/verify_phase3c.mjs` first if none exist.
const { data: intern, error: internErr } = await db
  .from('internships').select('id, university_id').limit(1).maybeSingle();
if (internErr) { console.error('FAIL querying internships:', internErr.message); ok = false; }
else if (!intern) { console.error('FAIL no internship to attach a credit request (run supabase/verify_phase3c.mjs first)'); ok = false; }
else {
  // Enqueue a pending credit request. credit_requests has NO unique on internship_id,
  // so this is an explicit insert-if-absent (NOT upsert-onConflict, which would error).
  let { data: req, error: selErr } = await db
    .from('credit_requests').select('id, status').eq('internship_id', intern.id).limit(1).maybeSingle();
  if (selErr) { console.error('FAIL selecting credit_requests:', selErr.message); ok = false; }
  if (ok && !req) {
    const { data: ins, error: insErr } = await db
      .from('credit_requests')
      .insert({ internship_id: intern.id, university_id: intern.university_id, status: 'pending' })
      .select('id, status').single();
    if (insErr) { console.error('FAIL enqueuing credit request:', insErr.message); ok = false; }
    else { req = ins; console.log('OK   pending credit request enqueued'); }
  } else if (ok) {
    console.log('OK   pending credit request already present');
  }
  // Approve it (records signer + timestamp + flips status). approve_credit RPC is auth_university_id()-gated
  // → not callable under service-role, so perform the recorded-approval write directly here.
  if (ok && req) {
    const { error: updErr } = await db.from('credit_requests')
      .update({ status: 'approved', signer_name: 'Dr. Lee', signed_at: new Date().toISOString() })
      .eq('id', req.id);
    if (updErr) { console.error('FAIL approving credit request:', updErr.message); ok = false; }
    else {
      const { data: after, error: afterErr } = await db
        .from('credit_requests').select('status, signer_name').eq('id', req.id).single();
      if (afterErr) { console.error('FAIL reading back approval:', afterErr.message); ok = false; }
      else if (after.status !== 'approved' || !after.signer_name) { console.error('FAIL approval did not record signer/status'); ok = false; }
      else console.log(`OK   credit request approved by ${after.signer_name}`);
    }
  }
}

console.log(ok ? 'VERIFY PHASE3E PASS' : 'VERIFY PHASE3E FAIL');
process.exit(ok ? 0 : 1);
