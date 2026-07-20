-- Phase 1: the student growth embedding (mirrors jobs.embedding) + a vector index on jobs.
alter table public.student_profiles
  add column if not exists growth_embedding extensions.vector(384);

-- ivfflat is trivial at seed scale; cosine ops. Safe to create now (empty/seeded after this push).
create index if not exists jobs_embedding_ivfflat
  on public.jobs using ivfflat (embedding extensions.vector_cosine_ops) with (lists = 10);
