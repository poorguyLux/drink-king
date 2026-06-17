-- ============================================================================
-- AINFINITY 第一届『饮料王』争霸赛 —— Supabase 建表 + 约束 + RLS
-- 在 Supabase 控制台 → SQL Editor 里整段粘贴执行即可。
-- ============================================================================

-- ---------- 表：rooms（房间） ----------
create table if not exists public.rooms (
  code        text primary key,                 -- 房间号（4~6 位，已去掉易混字符）
  host_token  text not null,                     -- 房主专属 token（轻量校验用）
  status      text not null default 'open',      -- 'open' / 'closed'（结算后冻结）
  created_at  timestamptz not null default now()
);

-- ---------- 表：scores（成绩） ----------
create table if not exists public.scores (
  id           uuid primary key default gen_random_uuid(),
  room_code    text not null,
  name         text not null,
  best_diff_ms int4,                             -- 最好成绩离目标的绝对差（毫秒，越小越强）
  best_raw_ms  int4,                             -- 最好那次的真实毫秒数（用于显示真实秒数）
  attempts     int4 not null default 0,          -- 已用次数（0 表示该行被“开新一局”清空，不进榜）
  updated_at   timestamptz not null default now()
);

-- (room_code, name) 唯一：便于“取最好成绩”的 upsert
create unique index if not exists scores_room_name_uniq
  on public.scores (room_code, name);

-- 排行榜按差值升序，建个索引顺手
create index if not exists scores_room_diff_idx
  on public.scores (room_code, best_diff_ms);

-- ---------- 开启 RLS ----------
alter table public.rooms  enable row level security;
alter table public.scores enable row level security;

-- ---------- 策略：匿名(anon) 允许 SELECT / INSERT / UPDATE，禁止 DELETE ----------
-- 说明：DELETE 不开放。所以“开新一局”不是删除，而是把该房间所有成绩的
--      attempts 重置为 0（前端只展示 attempts > 0 的行），等于清空了榜单并重置机会。

-- rooms
drop policy if exists rooms_select on public.rooms;
drop policy if exists rooms_insert on public.rooms;
drop policy if exists rooms_update on public.rooms;
create policy rooms_select on public.rooms for select to anon using (true);
create policy rooms_insert on public.rooms for insert to anon with check (true);
create policy rooms_update on public.rooms for update to anon using (true) with check (true);

-- scores
drop policy if exists scores_select on public.scores;
drop policy if exists scores_insert on public.scores;
drop policy if exists scores_update on public.scores;
create policy scores_select on public.scores for select to anon using (true);
create policy scores_insert on public.scores for insert to anon with check (true);
create policy scores_update on public.scores for update to anon using (true) with check (true);

-- （故意不创建任何 DELETE 策略 => anon 无法删除）

-- ============================================================================
-- 完成。回到 index.html 顶部 CONFIG，填上 SUPABASE_URL 和 SUPABASE_ANON_KEY。
-- ============================================================================
