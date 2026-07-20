import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;

const { data: gr, error: grErr } = await db.from('ghost_rate').select('*');
if (grErr) { console.error(`FAIL ghost_rate view: ${grErr.message}`); ok = false; }
else {
  const ghosted = (gr ?? []).find((r) => Number(r.ghosted) > 0);
  if (!ghosted) { console.error('FAIL no ghosted match found (did the seed backdate run?)'); ok = false; }
  else console.log(`OK   ghost_rate: a company shows ghost_rate=${ghosted.ghost_rate}`);
}

const { data: art, error: artErr } = await db.from('avg_response_time').select('*');
if (artErr) { console.error(`FAIL avg_response_time view: ${artErr.message}`); ok = false; }
else console.log(`OK   avg_response_time: ${(art ?? []).length} company rows`);

const { data: lb, error: lbErr } = await db.rpc('leaderboard');
if (lbErr) { console.error(`FAIL leaderboard(): ${lbErr.message}`); ok = false; }
else console.log(`OK   leaderboard(): ${(lb ?? []).length} companies`);

console.log(ok ? 'VERIFY PHASE2B PASS' : 'VERIFY PHASE2B FAIL');
process.exit(ok ? 0 : 1);
