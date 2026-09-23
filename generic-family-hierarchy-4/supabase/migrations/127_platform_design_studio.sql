-- VIS1 — Founder-controlled platform visual system.
-- Reuses the existing private community-media bucket; no new image service or paid transformation is introduced.
-- SOURCE ONLY. Apply explicitly to a target Supabase project after review.

create table if not exists public.platform_design_settings (
  singleton boolean primary key default true check(singleton),
  settings jsonb not null default '{"font_key":"humanist","layout_key":"balanced","hero_key":"immersive","corner_key":"rounded"}'::jsonb,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
insert into public.platform_design_settings(singleton) values(true) on conflict(singleton) do nothing;
alter table public.platform_design_settings enable row level security;
revoke all on public.platform_design_settings from anon,authenticated;

create table if not exists public.platform_visual_assets (
  slot_key varchar(140) primary key,
  bucket varchar(40) not null default 'community-media' check(bucket='community-media'),
  object_path text not null,
  thumbnail_path text,
  mime_type varchar(100) not null default 'image/webp',
  bytes bigint not null default 0 check(bytes>=0),
  thumbnail_bytes bigint not null default 0 check(thumbnail_bytes>=0),
  width integer,
  height integer,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint platform_visual_slot_chk check(slot_key ~ '^[a-z0-9][a-z0-9._-]{1,139}$'),
  constraint platform_visual_path_chk check(object_path like 'platform/%' and (thumbnail_path is null or thumbnail_path like 'platform/%'))
);
alter table public.platform_visual_assets enable row level security;
revoke all on public.platform_visual_assets from anon,authenticated;

create or replace function public.get_platform_design()
returns jsonb language sql security definer stable set search_path='' as $$
 select jsonb_build_object(
   'settings',coalesce((select s.settings from public.platform_design_settings s where s.singleton=true),'{}'::jsonb),
   'assets',coalesce((select jsonb_agg(jsonb_build_object(
     'slot_key',a.slot_key,'bucket',a.bucket,'object_path',a.object_path,'thumbnail_path',a.thumbnail_path,
     'mime_type',a.mime_type,'bytes',a.bytes,'thumbnail_bytes',a.thumbnail_bytes,'width',a.width,'height',a.height,'updated_at',a.updated_at
   ) order by a.slot_key) from public.platform_visual_assets a),'[]'::jsonb)
 );
$$;
revoke all on function public.get_platform_design() from public;
grant execute on function public.get_platform_design() to anon,authenticated;

create or replace function public.set_platform_design_settings(p_settings jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare next_settings jsonb;
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 next_settings:=jsonb_build_object(
   'font_key',coalesce(nullif(trim(p_settings->>'font_key'),''),'humanist'),
   'layout_key',coalesce(nullif(trim(p_settings->>'layout_key'),''),'balanced'),
   'hero_key',coalesce(nullif(trim(p_settings->>'hero_key'),''),'immersive'),
   'corner_key',coalesce(nullif(trim(p_settings->>'corner_key'),''),'rounded')
 );
 if next_settings->>'font_key' not in ('humanist','editorial','modern','system') then raise exception 'Unknown font preset.' using errcode='22023'; end if;
 if next_settings->>'layout_key' not in ('compact','balanced','spacious') then raise exception 'Unknown layout preset.' using errcode='22023'; end if;
 if next_settings->>'hero_key' not in ('immersive','split','clean') then raise exception 'Unknown hero preset.' using errcode='22023'; end if;
 if next_settings->>'corner_key' not in ('soft','rounded','square') then raise exception 'Unknown corner preset.' using errcode='22023'; end if;
 insert into public.platform_design_settings(singleton,settings,updated_by,updated_at)
 values(true,next_settings,auth.uid(),now())
 on conflict(singleton) do update set settings=excluded.settings,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
 return next_settings;
end $$;
revoke all on function public.set_platform_design_settings(jsonb) from public,anon;
grant execute on function public.set_platform_design_settings(jsonb) to authenticated;

create or replace function public.set_platform_visual_asset(
  p_slot_key text,p_object_path text,p_thumbnail_path text default null,p_mime_type text default 'image/webp',
  p_bytes bigint default 0,p_thumbnail_bytes bigint default 0,p_width integer default null,p_height integer default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare previous public.platform_visual_assets%rowtype;
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 if p_slot_key !~ '^[a-z0-9][a-z0-9._-]{1,139}$' then raise exception 'Invalid visual slot.' using errcode='22023'; end if;
 if coalesce(p_object_path,'') not like 'platform/'||auth.uid()::text||'/%' then raise exception 'Platform asset path is not owned by this account.' using errcode='42501'; end if;
 if nullif(p_thumbnail_path,'') is not null and p_thumbnail_path not like 'platform/'||auth.uid()::text||'/%' then raise exception 'Platform thumbnail path is not owned by this account.' using errcode='42501'; end if;
 select * into previous from public.platform_visual_assets where slot_key=p_slot_key;
 insert into public.platform_visual_assets(slot_key,bucket,object_path,thumbnail_path,mime_type,bytes,thumbnail_bytes,width,height,updated_by,updated_at)
 values(p_slot_key,'community-media',p_object_path,nullif(p_thumbnail_path,''),coalesce(nullif(p_mime_type,''),'image/webp'),greatest(coalesce(p_bytes,0),0),greatest(coalesce(p_thumbnail_bytes,0),0),p_width,p_height,auth.uid(),now())
 on conflict(slot_key) do update set object_path=excluded.object_path,thumbnail_path=excluded.thumbnail_path,mime_type=excluded.mime_type,
 bytes=excluded.bytes,thumbnail_bytes=excluded.thumbnail_bytes,width=excluded.width,height=excluded.height,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
 return jsonb_build_object('previous_object_path',previous.object_path,'previous_thumbnail_path',previous.thumbnail_path);
end $$;
revoke all on function public.set_platform_visual_asset(text,text,text,text,bigint,bigint,integer,integer) from public,anon;
grant execute on function public.set_platform_visual_asset(text,text,text,text,bigint,bigint,integer,integer) to authenticated;

create or replace function public.remove_platform_visual_asset(p_slot_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare previous public.platform_visual_assets%rowtype;
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 delete from public.platform_visual_assets where slot_key=p_slot_key returning * into previous;
 if not found then return '{}'::jsonb; end if;
 return jsonb_build_object('object_path',previous.object_path,'thumbnail_path',previous.thumbnail_path);
end $$;
revoke all on function public.remove_platform_visual_asset(text) from public,anon;
grant execute on function public.remove_platform_visual_asset(text) to authenticated;

-- Platform visuals are intentionally displayable before sign-in.
drop policy if exists platform_visuals_read on storage.objects;
create policy platform_visuals_read on storage.objects for select to anon,authenticated
using(bucket_id='community-media' and name like 'platform/%');

drop policy if exists platform_visuals_insert on storage.objects;
create policy platform_visuals_insert on storage.objects for insert to authenticated
with check(bucket_id='community-media' and name like 'platform/'||auth.uid()::text||'/%' and public.is_platform_owner());

drop policy if exists platform_visuals_update on storage.objects;
create policy platform_visuals_update on storage.objects for update to authenticated
using(bucket_id='community-media' and name like 'platform/'||auth.uid()::text||'/%' and public.is_platform_owner())
with check(bucket_id='community-media' and name like 'platform/'||auth.uid()::text||'/%' and public.is_platform_owner());

drop policy if exists platform_visuals_delete on storage.objects;
create policy platform_visuals_delete on storage.objects for delete to authenticated
using(bucket_id='community-media' and name like 'platform/'||auth.uid()::text||'/%' and public.is_platform_owner());

comment on table public.platform_visual_assets is 'Founder-managed landing, brand, Playground and platform visual slots stored in the existing community-media bucket.';
