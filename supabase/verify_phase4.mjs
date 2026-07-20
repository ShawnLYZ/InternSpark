import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;
const need = async (label, fn) => {
  try { const v = await fn(); if (v) console.log(`OK   ${label}`); else { console.error(`FAIL ${label}`); ok = false; } }
  catch (e) { console.error(`FAIL ${label}: ${e.message}`); ok = false; }
};

// At least one company past the min-sample gate (>=5 matches).
await need('leaderboard has a gated-past company (>=5 matches)', async () => {
  const { data } = await db.from('ghost_rate').select('total_matches');
  return (data ?? []).some((r) => Number(r.total_matches) >= 5);
});
// A non-zero ghost rate somewhere.
await need('a company shows ghost_rate > 0', async () => {
  const { data } = await db.from('ghost_rate').select('ghost_rate');
  return (data ?? []).some((r) => Number(r.ghost_rate) > 0);
});
// Placements → placement_rate > 0.
await need('placement_rate > 0 for the seeded university', async () => {
  const { data } = await db.from('placement_rate').select('placement_rate');
  return (data ?? []).some((r) => Number(r.placement_rate) > 0);
});
// Mentorship scores exist.
await need('company_mentorship_score has rows', async () => {
  const { data } = await db.from('company_mentorship_score').select('company_id');
  return (data ?? []).length > 0;
});
// Market demand is non-empty (ROI chart + gap).
await need('market_demand has rows', async () => {
  const { data } = await db.from('market_demand').select('skill_name');
  return (data ?? []).length > 0;
});

console.log(ok ? 'VERIFY PHASE4 PASS' : 'VERIFY PHASE4 FAIL');
process.exit(ok ? 0 : 1);
