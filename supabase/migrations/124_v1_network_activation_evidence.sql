-- V1 Network Activation Autopilot — evidence persistence
-- Additive only. Reuses the existing G9.1-A governed evidence tables.
-- This migration is source work only in V1; do not apply automatically.

create or replace function public.submit_family_association_activation_evidence(
  p_source jsonb,
  p_records jsonb
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  nid uuid:=public.current_network_id();
  sid uuid;
  existing_source uuid;
  r jsonb;
  inserted_count integer:=0;
  ext_id text;
begin
  if nid is null
     or (select vertical_kind from public.networks where id=nid)<>'family-association'
  then
    raise exception 'Family Community network required.' using errcode='22023';
  end if;

  if not public.is_network_admin(nid) then
    raise exception 'Network admin access required.' using errcode='42501';
  end if;

  ext_id:=coalesce(
    nullif(trim(p_source->>'externalId'),''),
    'network-activation:'||md5(coalesce(p_source->>'title','Activation source'))
  );

  select id into existing_source
  from public.network_knowledge_sources
  where network_id=nid and external_id=ext_id
  order by created_at desc
  limit 1;

  if existing_source is null then
    insert into public.network_knowledge_sources(
      network_id,
      source_type,
      external_id,
      title,
      uri,
      visibility,
      authorization_refs,
      content_hash,
      source_updated_at,
      last_observed_at,
      metadata
    )
    values(
      nid,
      'upload',
      ext_id,
      coalesce(nullif(trim(p_source->>'title'),''),'Network activation source'),
      null,
      'restricted',
      array['network-admin'],
      nullif(p_source->>'contentHash',''),
      nullif(p_source->>'sourceUpdatedAt','')::timestamptz,
      now(),
      coalesce(p_source->'metadata','{}'::jsonb)
        || jsonb_build_object('purpose','network-activation-autopilot','schemaVersion',p_source->>'schemaVersion')
    )
    returning id into sid;
  else
    sid:=existing_source;
    update public.network_knowledge_sources
    set
      last_observed_at=now(),
      content_hash=coalesce(nullif(p_source->>'contentHash',''),content_hash),
      source_updated_at=coalesce(nullif(p_source->>'sourceUpdatedAt','')::timestamptz,source_updated_at),
      metadata=metadata
        || coalesce(p_source->'metadata','{}'::jsonb)
        || jsonb_build_object('purpose','network-activation-autopilot','schemaVersion',p_source->>'schemaVersion')
    where id=sid;
  end if;

  for r in
    select * from jsonb_array_elements(coalesce(p_records,'[]'::jsonb))
  loop
    insert into public.network_evidence_records(
      network_id,
      source_id,
      document_external_id,
      chunk_id,
      title,
      uri,
      section,
      breadcrumb,
      content_hash,
      excerpt,
      source_updated_at,
      visibility,
      authorization_refs,
      extraction_version,
      metadata
    )
    values(
      nid,
      sid,
      nullif(r->>'documentExternalId',''),
      coalesce(nullif(r->>'chunkId',''),md5(coalesce(r->>'excerpt',''))),
      nullif(r->>'title',''),
      null,
      nullif(r->>'section',''),
      coalesce(r->'breadcrumb','[]'::jsonb),
      coalesce(nullif(r->>'contentHash',''),md5(coalesce(r->>'excerpt',''))),
      nullif(r->>'excerpt',''),
      nullif(r->>'sourceUpdatedAt','')::timestamptz,
      'restricted',
      array['network-admin'],
      coalesce(nullif(r->>'extractionVersion',''),'network-activation-candidate.v1'),
      coalesce(r->'metadata','{}'::jsonb)
        || jsonb_build_object('purpose','network-activation-autopilot')
    )
    on conflict(network_id,source_id,chunk_id,content_hash) do nothing;

    if found then inserted_count:=inserted_count+1;end if;
  end loop;

  insert into public.audit_log(network_id,actor_id,action,details)
  values(
    nid,
    auth.uid(),
    'family_association_activation_evidence_recorded',
    jsonb_build_object('source_id',sid,'inserted_evidence',inserted_count,'external_id',ext_id)
  );

  return jsonb_build_object('sourceId',sid,'insertedEvidence',inserted_count);
end
$$;

revoke all on function public.submit_family_association_activation_evidence(jsonb,jsonb) from public;
grant execute on function public.submit_family_association_activation_evidence(jsonb,jsonb) to authenticated;

create or replace function public.get_family_association_activation_evidence(
  p_limit integer default 200
)
returns table(
  evidence_id uuid,
  source_id uuid,
  source_title text,
  source_external_id text,
  chunk_id text,
  section text,
  excerpt text,
  captured_at timestamptz,
  metadata jsonb
)
language sql
security definer
stable
set search_path=public
as $$
  select
    e.id,
    e.source_id,
    s.title,
    s.external_id,
    e.chunk_id,
    e.section,
    e.excerpt,
    e.captured_at,
    e.metadata
  from public.network_evidence_records e
  join public.network_knowledge_sources s on s.id=e.source_id and s.network_id=e.network_id
  where e.network_id=public.current_network_id()
    and public.is_network_admin(e.network_id)
    and s.metadata->>'purpose'='network-activation-autopilot'
  order by e.captured_at desc,e.id
  limit greatest(1,least(coalesce(p_limit,200),1000));
$$;

revoke all on function public.get_family_association_activation_evidence(integer) from public;
grant execute on function public.get_family_association_activation_evidence(integer) to authenticated;
