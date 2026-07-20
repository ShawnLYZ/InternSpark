import { createClient } from '@supabase/supabase-js';

// Reset the stock golden-path demo state.
//
// The base seed (seed.mjs) intentionally leaves the Nimbus "Data Analyst Intern" job (JOB.data)
// UN-applied so the stock student@ + employer@ pair can walk the golden path live. Running the
// e2e (or a live demo) makes the hero swipe that job and drives it to `accepted` + an `internships`
// row. `seed.mjs` only UPSERTS — it can never un-swipe the hero — so a second run / a post-demo run
// would find no Nimbus card in the deck (dedup excludes already-swiped jobs).
//
// This service-role reset deletes any application on JOB.data (cascading its internship + sandbox
// submission via FK), re-surfacing the Nimbus card. Idempotent: deletes 0 rows when already clean.
//
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node supabase/reset_golden_path.mjs

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

const DATA_JOB = '33333333-3333-3333-3333-333333330001'; // Nimbus "Data Analyst Intern" (seed.mjs JOB.data)

const { data, error } = await db.from('applications').delete().eq('job_id', DATA_JOB).select('id');
if (error) { console.error(`reset failed: ${error.message}`); process.exit(1); }
console.log(`Golden-path reset: deleted ${data?.length ?? 0} application(s) on the Nimbus Data Analyst job — deck card re-surfaced.`);
