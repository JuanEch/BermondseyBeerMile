-- Run once in the Supabase SQL Editor to enable the admin page (open the app with #admin at the end of its URL).
-- Change the password on the line marked below before running. Run it again any time to change the password.
-- The password lives only in the database, not in the web page.

drop function if exists public.reset_crawl(text);  -- replaced by admin_action

create or replace function public.admin_action(pw text, action text, target text default null, value text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  removed text;
begin
  if pw is distinct from 'CHANGE-ME' then  -- <== your password goes here
    perform pg_sleep(1);  -- slows down guessing
    raise exception 'wrong password';
  end if;

  if action = 'check' then
    null;
  elsif action = 'rename_person' then
    if coalesce(trim(value), '') = '' then raise exception 'name required'; end if;
    update people set nickname = left(trim(value), 24), updated_at = now() where id::text = target;
    update photos set nickname = left(trim(value), 24) where person_id::text = target;
  elsif action = 'delete_person' then
    delete from people where id::text = target;
  elsif action = 'delete_photo' then
    delete from photos where id::text = target returning path into removed;
    return jsonb_build_object('ok', true, 'path', removed);
  elsif action = 'reset' then
    delete from people where true;
    delete from photos where true;
    update crawl_state set current = -1, closed = '[]'::jsonb, updated_at = now() where id = 1;
  else
    raise exception 'unknown action %', action;
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.admin_action(text, text, text, text) from public;
grant execute on function public.admin_action(text, text, text, text) to anon, authenticated;
