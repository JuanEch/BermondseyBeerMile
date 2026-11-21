-- Run once in the Supabase SQL Editor to enable the reset page (open the app with #reset at the end of its URL).
-- Change the password on the line marked below before running. Run it again any time to change the password.
-- The password lives only in the database, not in the web page.

create or replace function public.reset_crawl(pw text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if pw is distinct from 'CHANGE-ME' then  -- <== your password goes here
    perform pg_sleep(1);  -- slows down guessing
    raise exception 'wrong password';
  end if;
  delete from people where true;
  delete from photos where true;
  update crawl_state set current = -1, closed = '[]'::jsonb, updated_at = now() where id = 1;
end;
$$;

revoke all on function public.reset_crawl(text) from public;
grant execute on function public.reset_crawl(text) to anon, authenticated;
