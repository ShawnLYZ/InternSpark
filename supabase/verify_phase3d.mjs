import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'); process.exit(1); }
const db = createClient(url, key, { auth: { persistSession: false } });

let ok = true;
const { data: media, error } = await db.from('job_media').select('job_id, type, storage_path').eq('type', 'video');
if (error) { console.error(`FAIL job_media: ${error.message}`); ok = false; }
else if ((media ?? []).length < 1) { console.error('FAIL no video job_media (seed has one for the data job)'); ok = false; }
else console.log(`OK   ${media.length} video job_media row(s); deck will surface video_path`);

const { data: bucket } = await db.storage.getBucket('shadow-videos').catch(() => ({ data: null }));
console.log(bucket ? 'OK   shadow-videos bucket exists' : 'WARN shadow-videos bucket not found (check migration)');

console.log(ok ? 'VERIFY PHASE3D PASS' : 'VERIFY PHASE3D FAIL');
process.exit(ok ? 0 : 1);
