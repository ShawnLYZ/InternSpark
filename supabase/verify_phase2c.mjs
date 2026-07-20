import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;

const { data: md, error: mdErr } = await db.from('market_demand').select('*').order('demand', { ascending: false });
if (mdErr) { console.error(`FAIL market_demand: ${mdErr.message}`); ok = false; }
else if ((md ?? []).length < 1) { console.error('FAIL market_demand empty (seed jobs?)'); ok = false; }
else console.log(`OK   market_demand: top skill "${md[0].skill_name}" demand=${md[0].demand}`);

const { data: pr, error: prErr } = await db.from('placement_rate').select('*');
if (prErr) { console.error(`FAIL placement_rate: ${prErr.message}`); ok = false; }
else console.log(`OK   placement_rate: ${(pr ?? []).length} university rows`);

console.log(ok ? 'VERIFY PHASE2C PASS' : 'VERIFY PHASE2C FAIL');
process.exit(ok ? 0 : 1);
