-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

-- Hosted Supabase owns storage.buckets/storage.objects. Their RLS flags are verify-only here.
-- This file reconstructs bucket configuration only; no storage object/file rows are copied.
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types) VALUES ('community-media','community-media',false,1048576,NULL) ON CONFLICT(id) DO UPDATE SET name=excluded.name,public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types) VALUES ('profile-photos','profile-photos',false,1048576,NULL) ON CONFLICT(id) DO UPDATE SET name=excluded.name,public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
