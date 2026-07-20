import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;

const { data: jobs } = await db.from('jobs').select('id, embedding');
const embedded = (jobs ?? []).filter((j) => j.embedding != null).length;
if (embedded < 5) { console.error(`FAIL jobs embedded: ${embedded}/5`); ok = false; }
else console.log(`OK   jobs embedded: ${embedded}`);

const { data: sp } = await db.from('student_profiles')
  .select('growth_embedding').not('growth_embedding', 'is', null);
if ((sp ?? []).length < 1) { console.error('FAIL hero student growth_embedding missing'); ok = false; }
else console.log(`OK   student growth_embedding present`);

console.log(ok ? 'VERIFY PHASE1 PASS' : 'VERIFY PHASE1 FAIL');
process.exit(ok ? 0 : 1);
