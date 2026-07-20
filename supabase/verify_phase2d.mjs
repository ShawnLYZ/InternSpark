import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });
const BRIGHTWAY_ID = '22222222-2222-2222-2222-222222222222';

let ok = true;

const { data: agg, error: aggErr } = await db.from('company_mentorship_score').select('*').eq('company_id', BRIGHTWAY_ID).maybeSingle();
if (aggErr) { console.error(`FAIL company_mentorship_score: ${aggErr.message}`); ok = false; }
else if (!agg) { console.error('FAIL no mentorship aggregate for Brightway (seed review?)'); ok = false; }
else console.log(`OK   Brightway mentorship_score=${agg.mentorship_score} over ${agg.review_count} review(s)`);

// Anonymized read returns no author id.
const { data: rev, error: revErr } = await db.rpc('company_reviews', { p_company: BRIGHTWAY_ID });
if (revErr) { console.error(`FAIL company_reviews(): ${revErr.message}`); ok = false; }
else if ((rev ?? []).some((r) => 'student_id' in r)) { console.error('FAIL author id leaked in Brightway reviews'); ok = false; }
else console.log(`OK   Brightway company_reviews(): ${(rev ?? []).length} anonymized row(s), no author id`);

console.log(ok ? 'VERIFY PHASE2D PASS' : 'VERIFY PHASE2D FAIL');
process.exit(ok ? 0 : 1);
