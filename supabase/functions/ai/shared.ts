import { createClient } from 'npm:@supabase/supabase-js@2';

export const GEMINI_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.5-flash';
export const GEMINI_PRO_MODEL = Deno.env.get('GEMINI_PRO_MODEL') ?? 'gemini-2.0-pro';
export const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
export const DAILY_TOKEN_BUDGET = Number(Deno.env.get('AI_DAILY_TOKEN_BUDGET') ?? '200000');

export const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false } },
);

export async function cacheKey(task: string, input: string): Promise<string> {
  const data = new TextEncoder().encode(`${task}::${input}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function overBudget(): Promise<boolean> {
  const today = new Date().toISOString().slice(0, 10);
  const { data } = await admin.from('ai_budget').select('tokens_used').eq('day', today).maybeSingle();
  return (data?.tokens_used ?? 0) >= DAILY_TOKEN_BUDGET;
}

export async function addUsage(tokens: number): Promise<void> {
  const today = new Date().toISOString().slice(0, 10);
  const { data } = await admin.from('ai_budget').select('tokens_used, calls').eq('day', today).maybeSingle();
  await admin.from('ai_budget').upsert({
    day: today,
    tokens_used: (data?.tokens_used ?? 0) + tokens,
    calls: (data?.calls ?? 0) + 1,
  });
}
