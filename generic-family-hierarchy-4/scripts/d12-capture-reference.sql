-- D12 read-only catalog capture. Returns one JSON document; no application rows.
BEGIN TRANSACTION READ ONLY;
WITH app_ns AS (
  SELECT oid, nspname FROM pg_namespace
  WHERE nspname = 'public' OR nspname LIKE 'tw\_%' ESCAPE '\'
), relations AS (
  SELECT c.oid, n.nspname, c.relname, c.relkind, c.relrowsecurity, c.relforcerowsecurity
  FROM pg_class c JOIN app_ns n ON n.oid = c.relnamespace
  WHERE c.relkind IN ('r','p','v','m','f')
), captured AS (
 SELECT jsonb_build_object(
  'server_version', current_setting('server_version'),
  'database', current_database(),
  'schemas', (SELECT coalesce(jsonb_agg(nspname ORDER BY nspname),'[]'::jsonb) FROM app_ns),
  'relations', (SELECT coalesce(jsonb_agg(jsonb_build_object('name',format('%I.%I',nspname,relname),'kind',relkind,'rls',relrowsecurity,'force_rls',relforcerowsecurity) ORDER BY nspname,relname),'[]'::jsonb) FROM relations),
  'columns', (SELECT coalesce(jsonb_agg(jsonb_build_object('relation',format('%I.%I',r.nspname,r.relname),'name',a.attname,'type',format_type(a.atttypid,a.atttypmod),'not_null',a.attnotnull,'identity',a.attidentity,'generated',a.attgenerated,'default',pg_get_expr(d.adbin,d.adrelid)) ORDER BY r.nspname,r.relname,a.attnum),'[]'::jsonb) FROM relations r JOIN pg_attribute a ON a.attrelid=r.oid AND a.attnum>0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid=r.oid AND d.adnum=a.attnum),
  'constraints', (SELECT coalesce(jsonb_agg(jsonb_build_object('relation',format('%I.%I',r.nspname,r.relname),'name',c.conname,'kind',c.contype,'definition',pg_get_constraintdef(c.oid,true)) ORDER BY r.nspname,r.relname,c.conname),'[]'::jsonb) FROM pg_constraint c JOIN relations r ON r.oid=c.conrelid),
  'indexes', (SELECT coalesce(jsonb_agg(jsonb_build_object('relation',format('%I.%I',r.nspname,r.relname),'name',i.relname,'definition',pg_get_indexdef(i.oid)) ORDER BY r.nspname,r.relname,i.relname),'[]'::jsonb) FROM pg_index x JOIN relations r ON r.oid=x.indrelid JOIN pg_class i ON i.oid=x.indexrelid),
  'views', (SELECT coalesce(jsonb_agg(jsonb_build_object('name',format('%I.%I',r.nspname,r.relname),'definition',pg_get_viewdef(r.oid,true)) ORDER BY r.nspname,r.relname),'[]'::jsonb) FROM relations r WHERE r.relkind IN ('v','m')),
  'functions', (SELECT coalesce(jsonb_agg(jsonb_build_object('name',format('%I.%I',n.nspname,p.proname),'identity_arguments',pg_get_function_identity_arguments(p.oid),'result',pg_get_function_result(p.oid),'security_definer',p.prosecdef,'config',p.proconfig,'definition',pg_get_functiondef(p.oid)) ORDER BY n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)),'[]'::jsonb) FROM pg_proc p JOIN app_ns n ON n.oid=p.pronamespace WHERE p.prokind IN ('f','p','w')),
  'triggers', (SELECT coalesce(jsonb_agg(jsonb_build_object('relation',format('%I.%I',r.nspname,r.relname),'name',t.tgname,'definition',pg_get_triggerdef(t.oid,true),'enabled',t.tgenabled) ORDER BY r.nspname,r.relname,t.tgname),'[]'::jsonb) FROM pg_trigger t JOIN relations r ON r.oid=t.tgrelid WHERE NOT t.tgisinternal),
  'policies', (SELECT coalesce(jsonb_agg(jsonb_build_object('schema',schemaname,'table',tablename,'name',policyname,'permissive',permissive,'roles',roles,'command',cmd,'using',qual,'check',with_check) ORDER BY schemaname,tablename,policyname),'[]'::jsonb) FROM pg_policies WHERE schemaname IN (SELECT nspname FROM app_ns) OR schemaname='storage'),
  'grants', (SELECT coalesce(jsonb_agg(jsonb_build_object('schema',table_schema,'table',table_name,'grantee',grantee,'privilege',privilege_type,'grantable',is_grantable) ORDER BY table_schema,table_name,grantee,privilege_type),'[]'::jsonb) FROM information_schema.role_table_grants WHERE table_schema IN (SELECT nspname FROM app_ns) OR table_schema='storage'),
  'usage_grants', (SELECT coalesce(jsonb_agg(jsonb_build_object('schema',object_schema,'object',object_name,'type',object_type,'grantee',grantee,'privilege',privilege_type) ORDER BY object_schema,object_name,grantee,privilege_type),'[]'::jsonb) FROM information_schema.usage_privileges WHERE object_schema IN (SELECT nspname FROM app_ns) OR object_schema='storage'),
  'routine_grants', (SELECT coalesce(jsonb_agg(jsonb_build_object('schema',routine_schema,'name',routine_name,'specific_name',specific_name,'grantee',grantee,'privilege',privilege_type) ORDER BY routine_schema,specific_name,grantee,privilege_type),'[]'::jsonb) FROM information_schema.routine_privileges WHERE routine_schema IN (SELECT nspname FROM app_ns)),
  'extensions', (SELECT coalesce(jsonb_agg(jsonb_build_object('name',e.extname,'version',e.extversion,'schema',n.nspname) ORDER BY e.extname),'[]'::jsonb) FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace),
  'roles', (SELECT coalesce(jsonb_agg(jsonb_build_object('name',rolname,'login',rolcanlogin,'inherit',rolinherit,'bypass_rls',rolbypassrls) ORDER BY rolname),'[]'::jsonb) FROM pg_roles WHERE rolname !~ '^pg_'),
  'storage_relation_present',to_regclass('storage.buckets') IS NOT NULL,
  'migration_relation_present',to_regclass('supabase_migrations.schema_migrations') IS NOT NULL
 ) AS doc
)
SELECT doc::text FROM captured;
COMMIT;
