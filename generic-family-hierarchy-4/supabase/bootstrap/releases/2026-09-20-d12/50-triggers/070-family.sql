-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TRIGGER trg_protect_foundational_family_relationship BEFORE DELETE ON family_relationships FOR EACH ROW EXECUTE FUNCTION protect_foundational_family_relationship();
CREATE TRIGGER trg_validate_family_relationship BEFORE INSERT OR UPDATE ON family_relationships FOR EACH ROW EXECUTE FUNCTION validate_family_relationship();
CREATE TRIGGER validate_profile_submission_media_trigger BEFORE INSERT OR UPDATE OF photo_url ON profile_submissions FOR EACH ROW EXECUTE FUNCTION validate_profile_submission_media();
