-- ============================================================
-- NeuralGrowth Database Schema
-- ============================================================

-- Enable required extensions
create extension if not exists "pgcrypto";

-- ============================================================
-- Users
-- ============================================================
create table public.users (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  threads_token text,
  linkedin_token text,
  threads_handle text,
  linkedin_name text,
  niche_tags text[] default '{}',
  tone_preference text default 'professional',
  language_preference text default 'english',
  hook_formats text[] default '{}',
  created_at timestamptz default now()
);

alter table public.users enable row level security;

create policy "Users can view their own data"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can insert their own data"
  on public.users for insert
  with check (auth.uid() = id);

create policy "Users can update their own data"
  on public.users for update
  using (auth.uid() = id);

-- ============================================================
-- Posts
-- ============================================================
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users on delete cascade,
  content_threads text,
  content_linkedin text,
  platforms text[] default '{}',
  status text default 'draft',
  post_type text default 'text',
  scheduled_at timestamptz,
  published_at timestamptz,
  threads_post_id text,
  linkedin_post_id text,
  media_urls text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.posts enable row level security;

create policy "Users can view their own posts"
  on public.posts for select
  using (auth.uid() = user_id);

create policy "Users can insert their own posts"
  on public.posts for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own posts"
  on public.posts for update
  using (auth.uid() = user_id);

create policy "Users can delete their own posts"
  on public.posts for delete
  using (auth.uid() = user_id);

-- Enable realtime on posts
alter publication supabase_realtime add table public.posts;

-- ============================================================
-- Engagement Pool
-- ============================================================
create table public.engagement_pool (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users on delete cascade,
  threads_post_id text,
  author_handle text,
  content text,
  likes int default 0,
  replies int default 0,
  permalink text,
  saved boolean default false,
  trashed boolean default false,
  liked_by_user boolean default false,
  refreshed_at timestamptz default now(),
  expires_at timestamptz
);

alter table public.engagement_pool enable row level security;

create policy "Users can view their own engagement pool"
  on public.engagement_pool for select
  using (auth.uid() = user_id);

create policy "Users can insert into their own engagement pool"
  on public.engagement_pool for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own engagement pool"
  on public.engagement_pool for update
  using (auth.uid() = user_id);

create policy "Users can delete from their own engagement pool"
  on public.engagement_pool for delete
  using (auth.uid() = user_id);

-- ============================================================
-- AI Content Pool
-- ============================================================
create table public.ai_content_pool (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users on delete cascade,
  content text,
  platform text default 'threads',
  status text default 'draft',
  hook_type text,
  topic text,
  tone text default 'professional',
  generated_at timestamptz default now(),
  used_at timestamptz
);

alter table public.ai_content_pool enable row level security;

create policy "Users can view their own ai content"
  on public.ai_content_pool for select
  using (auth.uid() = user_id);

create policy "Users can insert their own ai content"
  on public.ai_content_pool for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own ai content"
  on public.ai_content_pool for update
  using (auth.uid() = user_id);

create policy "Users can delete their own ai content"
  on public.ai_content_pool for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Analytics Cache
-- ============================================================
create table public.analytics_cache (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users on delete cascade,
  platform text,
  metric_type text,
  value numeric,
  period text,
  fetched_at timestamptz default now()
);

alter table public.analytics_cache enable row level security;

create policy "Users can view their own analytics"
  on public.analytics_cache for select
  using (auth.uid() = user_id);

create policy "Users can insert their own analytics"
  on public.analytics_cache for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own analytics"
  on public.analytics_cache for update
  using (auth.uid() = user_id);

create policy "Users can delete their own analytics"
  on public.analytics_cache for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Indexes
-- ============================================================
create index idx_posts_user_id on public.posts (user_id);
create index idx_posts_status on public.posts (status);
create index idx_posts_scheduled_at on public.posts (scheduled_at);
create index idx_engagement_pool_user_id on public.engagement_pool (user_id);
create index idx_engagement_pool_trashed on public.engagement_pool (trashed);
create index idx_ai_content_pool_user_id on public.ai_content_pool (user_id);
create index idx_ai_content_pool_status on public.ai_content_pool (status);
create index idx_analytics_cache_user_id on public.analytics_cache (user_id);
create index idx_analytics_cache_platform on public.analytics_cache (platform);

-- ============================================================
-- Updated-at trigger for posts
-- ============================================================
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_posts_updated
  before update on public.posts
  for each row
  execute function public.handle_updated_at();
