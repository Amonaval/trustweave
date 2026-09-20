# M3-D Final Architecture Scorecard — D0 vs D11

This scorecard compares source/CI architecture evidence. It is not a production-traffic certification.

| Dimension | D0 evidence | D11 state |
| --- | --- | --- |
| Addressability | Hidden in-app selected network/view state; legacy notification query links | Canonical `/network/{networkId}/{surface}` grammar, direct-entry contract, return-to-origin and route fitness tests |
| Vertical registration | Multiple parallel concepts/touchpoints | Canonical manifest + derived registries + deterministic D10 integration plan |
| Capability ownership | Capability vocabulary existed without one inspectable ownership inventory | Typed capability manifest with source/API/persistence/policy/workflow/observability/loading metadata |
| Authorization | Predominantly role/RLS-specific behavior | Shared resource/relationship/purpose/time/consent decision contract + thin vertical adapters |
| Action lifecycle | D0 explicitly found no proven shared absence/homework/pickup lifecycle | Shared D5 task/acknowledgement/approval/consent/assignment/due/SLA/audit primitives |
| Data/API boundaries | D0 counted 158 source lines containing direct `supabase.rpc(` across app/component/capability/vertical/lib areas | D6 server query/command runtime established and representative Housing/FCA + D8 page APIs migrated; legacy direct RPC remains explicitly inventoried rather than falsely eliminated |
| Runtime footprint | D1 build measured 754 kB First Load JS and static vertical imports | D7 lazy boundaries; root First Load JS measured 644 kB with 700 kB CI ceiling |
| Multi-tenant scale | Full-list reads and user-only process burst limits existed | D8 network burst limits, page caps, keyset APIs, graph/export/import budgets, scale escalation triggers |
| Observability | Raw actor/network IDs in logs; no SLO contract; health only said healthy | D9 privacy-safe tags, capability/journey telemetry, slow thresholds, executable SLO/error-budget contracts and honest health |
| Vertical developer experience | Engineer/architect had to remember registration, policy, routes, seed, QA, bundle rules | D10 one blueprint + typed adapters + scaffold CLI + explicit five-point integration plan |
| School proof | D0 identified student/guardian reuse but action lifecycle gaps and unsafe detail-route gaps | D11: A=1, B=9, C=0, D=2; School can start as thin vertical while remaining unregistered until implementation gates pass |

## Residual architecture debt

D11 does not erase known debt:

- legacy direct UI/capability RPC paths still exist outside the migrated D6 boundaries;
- D1 authenticated connected-browser certification remains environment-dependent;
- migration 122 / two-vertical connected reliability closure remains open;
- D8 production query-plan evidence needs representative connected data;
- D9 long-window SLOs need durable external telemetry;
- resource-detail routes remain capability-by-capability work.

These are bounded backlog items, not reasons to invent a second School architecture.
