# TrustWeave — Launch Seed Reuse Contract

**Status:** Binding contract for bundled Residential and Family Community launch datasets  
**Date:** 2026-09-22

## Goal

Running the same canonical synthetic launch dataset repeatedly against the **same active network** must reuse/skip the records already created instead of producing duplicate seed data.

Canonical bundled datasets:

- Residential — 25 flats: `trustweave-launch-residential.v1`
- Family Community — 20 families: `trustweave-launch-family-community.v1`

The bundled JSON and the equivalent default XLSX share the same dataset version. Stable logical references such as Unit ID, Resident ID, Family ID, Person ID, Event Ref, Ballot Ref and similar section keys identify the same seed row.

## Existing mechanism

The launch-data system records lineage by:

`network_id + dataset_version + section_key + row_ref`

and stores:

- the source payload hash;
- the remote database ID;
- completion/status metadata.

The runner therefore behaves as follows:

1. **Same network + same dataset version + same row ref + unchanged payload:** skip mutation and return the existing remote ID.
2. **Same network + same logical row but changed mutable payload:** call the mutator with the existing remote ID so the product API can update/reuse that record.
3. **Historical/immutable row changed:** do not silently create a duplicate; preserve the existing record and surface a warning.
4. **Interrupted/partial row:** preserve the known remote ID and resume the remaining transition rather than blindly creating another row.
5. **Different network:** create/reuse records inside that network's own lineage. Never point a second tenant/network at the first network's owned entity merely because the synthetic source row is identical.

## Identity versus network-owned records

A real human account may participate in multiple networks through the existing identity/membership model. That does **not** mean network-owned entities, memberships, units, households, events, ballots, payments or governance records should be shared across tenants.

Cross-network reuse must happen through explicit shared-identity/federation contracts, not by reusing another network's row ID.

## Canonical-path rule

For the bundled/default Residential and Family Community datasets, prefer the Launch Data Loader / launch-seed capability. Do not add parallel ad-hoc SQL seed scripts that bypass lineage and then expect the same idempotence guarantee.

If a future seed/import path must coexist with these datasets, it should either:

- call the same lineage-aware capability; or
- first prove an equivalent network-scoped idempotency contract.

## Alpha acceptance

For the same network and unchanged bundled dataset, a repeat dry run should report those lineage-backed rows as **skip**, not **create**. A commit rerun should retain the same remote IDs.

This contract does not require cross-network row sharing and must never weaken tenant isolation.
