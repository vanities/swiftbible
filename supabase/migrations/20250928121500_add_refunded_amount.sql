alter table public.donations
  add column if not exists refunded_amount_cents integer not null default 0;
