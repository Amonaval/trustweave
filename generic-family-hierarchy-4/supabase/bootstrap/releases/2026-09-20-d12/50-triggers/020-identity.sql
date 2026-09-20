-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TRIGGER trg_profiles_clear_family_lobby BEFORE INSERT OR UPDATE OF active_network_id ON profiles FOR EACH ROW EXECUTE FUNCTION clear_family_lobby_on_activation();
