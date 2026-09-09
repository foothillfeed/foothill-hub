-- Foothill Hub: availability + hours-wanted schema
-- Run once in Supabase → SQL Editor. Safe to re-run (IF NOT EXISTS everywhere).

create table if not exists ff_availability (
  uid          text primary key,
  rules        jsonb   not null default '[]'::jsonb,   -- existing availability rules per day
  target_hours integer not null default 0,             -- desired hours per week (0 = no target)
  max_days     integer not null default 5,             -- max days per week
  can_open     boolean not null default true,
  can_close    boolean not null default true,
  fill_only    boolean not null default false,         -- on-call: schedule only to cover a gap
  updated_at   timestamptz default now()
);

-- If the table already existed with only uid + rules, add the new columns:
alter table ff_availability add column if not exists target_hours integer not null default 0;
alter table ff_availability add column if not exists max_days     integer not null default 5;
alter table ff_availability add column if not exists can_open     boolean not null default true;
alter table ff_availability add column if not exists can_close    boolean not null default true;
alter table ff_availability add column if not exists fill_only    boolean not null default false;
alter table ff_availability add column if not exists updated_at   timestamptz default now();

-- Match the access pattern the rest of the Hub tables use (anon key read/write).
-- Skip this block if your other ff_ tables don't use RLS policies like this.
alter table ff_availability enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename = 'ff_availability' and policyname = 'ff_availability_all') then
    create policy ff_availability_all on ff_availability for all using (true) with check (true);
  end if;
end $$;

-- Coverage settings are stored in the existing ff_so_settings table under
-- setting_key = 'sched_coverage' — no new table needed for those.
