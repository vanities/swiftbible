set check_function_bodies = off;

create table if not exists public.donations (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    user_id uuid references auth.users(id) on delete set null,
    anonymous_id text,
    amount_cents integer not null check (amount_cents > 0),
    currency text not null default 'usd',
    stripe_session_id text not null unique,
    stripe_payment_intent_id text,
    status text not null default 'unpaid',
    donor_email text,
    metadata jsonb not null default '{}'::jsonb
);

create index if not exists donations_user_id_idx on public.donations(user_id);
create index if not exists donations_anonymous_id_idx on public.donations(anonymous_id);
create index if not exists donations_status_idx on public.donations(status);

create or replace function public.set_donations_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$ language plpgsql;

create trigger set_donations_timestamp
before update on public.donations
for each row execute function public.set_donations_updated_at();

alter table public.donations enable row level security;

create policy "Users can view their donations" on public.donations
for select using (auth.uid() = user_id);

create policy "Service role can manage donations" on public.donations
for all to service_role using (true) with check (true);
