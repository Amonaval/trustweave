# TrustWeave — Lessons, Failure Patterns & Kill List

**Status:** CANONICAL LEARNING / ANTI-DRIFT FILE  
**Effective:** 2026-09-23

This file exists so TrustWeave does not repeatedly pay for the same mistakes.

> **Failing once can create learning. Repeating an already-understood failure is waste.**

## Product lessons already paid for

### Incomplete object lifecycle is not product depth

We have seen features that could be created but not properly viewed, edited, deleted, inspected, shared or administered; groups with no meaningful details/members; and share actions that shared text rather than a useful deep link.

**Rule:** prefer complete user outcomes and object lifecycle over another feature tile.

### Hidden capability has near-zero value

TrustWeave accumulated strong capability that ordinary users could not discover without narration.

**Rule:** navigation, task language, progressive disclosure and obvious next actions are part of the feature.

### “Works” is not the same as “people want to use it”

Community functionality was operationally useful but visually flat. Human/media composition changed the adoption story.

**Rule:** emotional and visual quality matters in voluntary-use products.

### Admin breadth can destroy usability

Large stacked Housing screens proved that powerful functionality can become unusable through density.

**Rule:** expose one primary task area at a time; use workspaces/tabs/selectors/contained lists rather than endless peer modules.

### A TrustWeave-shaped import template shifts work to the customer

Network Activation showed that requiring users to pre-normalize ordinary spreadsheets undermines the value proposition.

**Rule:** humans confirm semantics; machines scale transformation. Never silently guess trusted data.

## Engineering / architecture lessons already paid for

### Do not duplicate vertical implementations

Event/post/group lifecycle belonged once in Shared Community Objects rather than separate MPF, Residential, Alumni and future implementations.

**Rule:** search for shared semantics first. Reuse when meaning matches; separate when meaning truly differs.

### Source-green is not runtime proof

Real seeded/runtime usage exposed missing RPCs, Storage behavior, state and UX defects after static work looked correct.

**Rule:** state evidence honestly. Runtime claims require runtime evidence.

### Broad recovery/QA can consume unlimited time

D12 produced valuable recoverability/architecture proof, but exhaustive perfection eventually had sharply diminishing product return.

**Rule:** when the strategic question is answered, stop unless a concrete risk justifies continuation.

### Experimental SQL + bootstrap drift creates expensive mess

Storage/runtime fixes demonstrated the cost of speculative migrations and divergent bootstrap state.

**Rule:** reproduce the concrete runtime issue, preserve migration history, create a final repair migration, and synchronize only final effective behavior into current bootstrap.

### Micro-commits create noise

Large numbers of tool-generated small commits made history harder to understand.

**Rule:** default to 1–5 coherent commits, approximately 5–10 only for substantial work, unless rollback/bisect/security/migration sequencing genuinely benefits.

### Stale docs can redirect the company

Top-level documents continued to describe older architecture/autonomy work as “active” after product priorities changed.

**Rule:** current strategic authority must be obvious at session start. Historical truth never silently becomes current priority.

## UX/runtime lessons already paid for

- Mobile safe areas and reachable navigation must be observed, not assumed from CSS.
- Playground/demo state must clear correctly when switching verticals.
- Signed-out and dark public surfaces must remain usable.
- Attendee/member identities can matter more than aggregate counts.
- Governance wording must distinguish real statutory/committee processes from ordinary app polls.
- Shared CSS/visual rules can regress unrelated positioning/stacking.
- Uploads must show users where assets went and expose lifecycle/inventory.
- Share actions should share an authorized useful destination.
- Loading, success, error and recovery are part of the journey.
- A successful primary write must not look failed because optional secondary hydration failed.

## Kill list — intentionally avoid

### Product

- shallow vertical proliferation;
- feature-count roadmaps;
- generic social feeds as the engagement strategy;
- capability users cannot discover;
- custom code per customer when shared capability/configuration works;
- building another vertical while active pilots expose fundamental reusable gaps;
- marketplace/ecosystem build before repeated extension demand;
- replacing specialist systems without evidence when integration is stronger.

### AI

- chatbot-for-marketing;
- AI that ignores TrustWeave structured context;
- opaque sensitive recommendations;
- silent AI mutation of trusted data;
- paid inference for deterministic tasks;
- architecture permanently coupled to one model/vendor.

### Architecture

- architecture astronautics;
- abstractions with no active consumer;
- forced genericity that erases domain meaning;
- Kafka/Jenkins/queues/microservices because “mature systems use them”;
- rewrites when evolution is sufficient;
- generic platform work before a real product requirement proves the primitive.

### Quality

- broad suites by default;
- reopening closed recovery programs because they could be more perfect;
- source-only evidence presented as runtime/pilot proof;
- tests that certify the harness while missing the real journey;
- weakening QA until a broken product appears green.

### Data / Supabase

- rewriting historical migrations;
- speculative columns/functions added only to satisfy code;
- experimental patches in bootstrap;
- broad permissions to solve narrow UX problems;
- client-side privacy hiding treated as authorization;
- cross-network access inferred from membership elsewhere.

### Delivery / Founder time

- endless planning before a bounded high-value action;
- 20-step missions when 3 steps answer the question;
- dozens of micro-commits;
- repeatedly asking Founder to relay routine logs/errors;
- Founder hours explaining a demo that should explain itself;
- paid/metered resource use without explicit cost warning and consent.

### Documentation

- new docs merely because a conversation happened;
- the same status paragraph copied everywhere;
- old NEXT-SESSION notes treated as authority;
- historical evidence returning to root;
- contradictory “current” missions;
- long documents whose key rule is difficult to find.

## Red flags requiring strategic review before coding

Pause when the proposed reasoning sounds like:

- “We can make this 100% perfect.”
- “While we are here, we should also…”
- “This will be useful someday.”
- “Every vertical needs its own version.”
- “Let's add Kafka/Jenkins/microservices now for future scale.”
- “The build passes, so the journey is done.”
- “We need more features before showing users.”
- “The user can learn it from documentation.”
- “We'll fix discoverability later.”
- “Let's create another migration and try it.”
- “Let's run all QA again just to be safe” when broad risk did not change.
- “AI can guess the missing trusted data.”
- “It is free tier, so billing does not need checking.”

## Permanent recovery behavior

When something fails:

1. classify product / contract / data / environment / harness / UX / documentation;
2. reproduce the smallest concrete failure;
3. fix the root contract instead of layering patches;
4. preserve tenant/security boundaries;
5. verify the affected journey;
6. capture a durable lesson only if it generalizes;
7. stop when the mission question is answered.
