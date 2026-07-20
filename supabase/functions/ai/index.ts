import { admin, cacheKey, overBudget, addUsage, GEMINI_API_KEY, GEMINI_MODEL, GEMINI_PRO_MODEL } from './shared.ts';
import { handleVerification } from './verification.ts';

// `Supabase.ai` is provided by the Edge Runtime; declare to satisfy TS.
declare const Supabase: { ai: { Session: new (model: string) => { run: (text: string, opts: Record<string, unknown>) => Promise<number[]> } } };

const PRO_TASKS = ['resume', 'report_draft', 'credit_map', 'sandbox_gen', 'sandbox_assess'];
const modelFor = (task: string) => (PRO_TASKS.includes(task) ? GEMINI_PRO_MODEL : GEMINI_MODEL);

const embedder = new Supabase.ai.Session('gte-small');

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const { task, input, prompt } = body;

    if (task === 'verification_start' || task === 'verification_advance') {
      return await handleVerification(task, req, body);
    }

    if (task === 'embed') {
      const text = String(input ?? prompt ?? '');
      const embedding = await embedder.run(text, { mean_pool: true, normalize: true });
      return Response.json({ task, embedding });
    }

    const GENERATE_TASKS = ['generate', 'rationale', 'growth_draft', 'resume', 'report_draft', 'credit_map', 'sandbox_gen', 'sandbox_assess'];
    if (GENERATE_TASKS.includes(task)) {
      const p = String(prompt ?? input ?? '');
      const key = await cacheKey(task, p);

      const { data: cached } = await admin.from('ai_cache').select('response').eq('cache_key', key).maybeSingle();
      if (cached) return Response.json({ ...cached.response, cached: true });

      if (await overBudget()) {
        return Response.json({ task, text: `[${task} unavailable — budget reached]`, usedFallback: true });
      }

      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${modelFor(task)}:generateContent`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
          body: JSON.stringify({ contents: [{ parts: [{ text: p }] }] }),
        },
      );
      if (!res.ok) {
        return Response.json({ task, text: `[${task} unavailable — please try again later]`, usedFallback: true });
      }
      const resBody = await res.json();
      const text = resBody?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
      const payload = { task, text, usedFallback: false };
      await admin.from('ai_cache').upsert(
        { cache_key: key, task, response: payload },
        { onConflict: 'cache_key', ignoreDuplicates: true },
      );
      await addUsage(text.length);
      return Response.json(payload);
    }

    return Response.json({ error: `Unknown task: ${task}` }, { status: 400 });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500 });
  }
});
