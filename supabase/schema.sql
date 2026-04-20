create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,
  nickname text not null,
  favorite_team text,
  avatar_seed text not null default 'D',
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  external_match_id text unique,
  league text not null default 'NBA',
  home_team_name text not null,
  away_team_name text not null,
  home_team_code text not null,
  away_team_code text not null,
  start_time timestamptz not null,
  status text not null default 'upcoming',
  featured boolean not null default false,
  featured_tag text,
  result_payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists match_questions (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references matches(id) on delete cascade,
  question_type text not null,
  title text not null,
  description text,
  deadline timestamptz not null,
  options jsonb not null,
  settlement_key text,
  settlement_threshold numeric,
  created_at timestamptz not null default now()
);

create table if not exists match_submissions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  match_id uuid not null references matches(id) on delete cascade,
  submitted_at timestamptz not null default now(),
  status text not null default 'pending',
  unique (profile_id, match_id)
);

create table if not exists submission_answers (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references match_submissions(id) on delete cascade,
  question_id uuid not null references match_questions(id) on delete cascade,
  answer_value text not null,
  settlement_state text not null default 'pending',
  is_correct boolean,
  created_at timestamptz not null default now(),
  unique (submission_id, question_id)
);

create table if not exists user_match_performance (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  match_id uuid not null references matches(id) on delete cascade,
  answered_count int not null default 0,
  correct_count int not null default 0,
  accuracy numeric not null default 0,
  score_delta int not null default 0,
  is_win boolean not null default false,
  perfect_bonus boolean not null default false,
  streak_bonus boolean not null default false,
  created_at timestamptz not null default now(),
  unique (profile_id, match_id)
);

create table if not exists leaderboard_snapshots (
  id uuid primary key default gen_random_uuid(),
  snapshot_scope text not null,
  snapshot_date date not null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_matches_start_time on matches(start_time);
create index if not exists idx_questions_match_id on match_questions(match_id);
create index if not exists idx_submissions_profile_match on match_submissions(profile_id, match_id);
create index if not exists idx_answers_submission_id on submission_answers(submission_id);
create index if not exists idx_performance_profile on user_match_performance(profile_id);

create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_profiles_updated_at
before update on profiles
for each row
execute function update_updated_at_column();

create trigger set_matches_updated_at
before update on matches
for each row
execute function update_updated_at_column();
