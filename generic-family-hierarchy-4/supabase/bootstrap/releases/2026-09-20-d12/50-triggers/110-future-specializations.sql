-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TRIGGER trg_g7_remove_alumni_profile AFTER DELETE ON alumni_profiles FOR EACH ROW EXECUTE FUNCTION g7_sync_alumni_profile();
CREATE TRIGGER trg_g7_sync_alumni_profile AFTER INSERT OR UPDATE OF full_name, graduation_year, program, department, city, company, visibility, claimed_by ON alumni_profiles FOR EACH ROW EXECUTE FUNCTION g7_sync_alumni_profile();
