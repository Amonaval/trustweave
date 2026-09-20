# D12 fresh bootstrap CI replay

This workflow applies only the 94 committed direct SQL files to a **new, empty,
disposable** Supabase project. It never targets the golden project, the earlier
candidate, Clean Replay, or the old QA Replay. A fresh public-schema preflight
also rejects a populated target. The 95th Storage owner-context file remains a
separate later gate.

## Prepare and trigger

1. Create a new disposable Supabase project in the Personal organization, and
   retain its 20-character project ref. Do not reuse an existing D12 project.
2. In that project's **Connect → Session pooler** dialog, copy the
   `postgresql://postgres.<project-ref>:...@aws-...pooler.supabase.com:5432/postgres`
   URL and replace the password placeholder. Percent-encode reserved password
   characters. The session pooler works from GitHub's IPv4-only hosted runner.
   Use port **5432**; transaction pooler port 6543 is refused.
3. In GitHub repository **Settings → Secrets and variables → Actions**, create
   repository secret `D12_BOOTSTRAP_DATABASE_URL` containing that URL. Do not
   paste it into a commit, issue, chat, or workflow input.
4. Only when the secret and new project are ready, commit `.d12-ci/READY.json`
   to `llm-push` with exactly this object (using the new project ref and the
   SHA-256 of the committed release `manifest.json`):

   ```json
   {
     "format": "trustweave-d12-fresh-replay-v1",
     "candidate_project_ref": "<new-20-character-ref>",
     "golden_project_ref": "yyhwcqpzplebittvxzzl",
     "manifest_sha256": "<64-character-sha256>"
   }
   ```

The marker change is the only push path that starts the replay. The workflow
checks out that exact commit, validates the marker and release checksum, and
runs the guarded apply script. It publishes only a seven-day secret-free apply
receipt artifact. A rerun against an already populated project fails the
freshness check. Do not log or commit connection strings. Keep the repository
secret scoped to this short-lived replay and remove it after evidence capture.

A successful apply receipt is **not** full D12 certification. Storage
owner-context execution, candidate catalog/ACL and API parity, database
behavior, and bounded Housing/Family browser journeys remain separate gates.
