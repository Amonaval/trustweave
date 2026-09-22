-- D12 supplement for the Supabase SQL Editor. Read-only, one JSON row.
-- Run separately from d12-capture-reference.sql, then export CSV.
WITH app_ns AS (
 SELECT oid,nspname,nspacl FROM pg_namespace WHERE nspname='public' OR nspname LIKE 'tw\_%' ESCAPE '\'
), captured AS (
 SELECT jsonb_build_object(
  'server_version',current_setting('server_version'),
  'enums',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'type',t.typname,'label',e.enumlabel,'order',e.enumsortorder) ORDER BY n.nspname,t.typname,e.enumsortorder),'[]'::jsonb)
    FROM pg_type t JOIN app_ns n ON n.oid=t.typnamespace JOIN pg_enum e ON e.enumtypid=t.oid),
  'domains',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',t.typname,'base_type',format_type(t.typbasetype,t.typtypmod),'not_null',t.typnotnull,'default',t.typdefault) ORDER BY n.nspname,t.typname),'[]'::jsonb)
    FROM pg_type t JOIN app_ns n ON n.oid=t.typnamespace WHERE t.typtype='d'),
  'sequences',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',c.relname,'data_type',format_type(s.seqtypid,NULL),'start',s.seqstart,'increment',s.seqincrement,'min',s.seqmin,'max',s.seqmax,'cache',s.seqcache,'cycle',s.seqcycle) ORDER BY n.nspname,c.relname),'[]'::jsonb)
    FROM pg_sequence s JOIN pg_class c ON c.oid=s.seqrelid JOIN app_ns n ON n.oid=c.relnamespace),
  'schema_grants',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'acl',n.nspacl::text) ORDER BY n.nspname),'[]'::jsonb) FROM app_ns n),
  'relation_grants',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',c.relname,'acl',c.relacl::text) ORDER BY n.nspname,c.relname),'[]'::jsonb) FROM pg_class c JOIN app_ns n ON n.oid=c.relnamespace WHERE c.relkind IN ('r','p','v','m','S')),
  'function_grants',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,'identity_arguments',pg_get_function_identity_arguments(p.oid),'acl',p.proacl::text) ORDER BY n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)),'[]'::jsonb) FROM pg_proc p JOIN app_ns n ON n.oid=p.pronamespace),
  'storage_buckets',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'public',public,'file_size_limit',file_size_limit,'allowed_mime_types',allowed_mime_types) ORDER BY id),'[]'::jsonb) FROM storage.buckets),
  'storage_relation_security',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',c.relname,'rls',c.relrowsecurity,'force_rls',c.relforcerowsecurity,'acl',c.relacl::text) ORDER BY c.relname),'[]'::jsonb) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='storage' AND c.relname IN ('buckets','objects')),
  'contract_rpc_presence',jsonb_build_object(
    'set_network_notification_role',to_regprocedure('public.set_network_notification_role(text,text,uuid,boolean)') IS NOT NULL,
    'remove_network_notification_role',to_regprocedure('public.remove_network_notification_role(text,uuid)') IS NOT NULL,
    'reconcile_network_media_usage',to_regprocedure('public.reconcile_network_media_usage(uuid)') IS NOT NULL),
  'migration_relation_present',to_regclass('supabase_migrations.schema_migrations') IS NOT NULL
 ) doc
)
SELECT doc::text FROM captured;
