# VIS3 — Product Story & Share Asset Map

**Date:** 2026-09-23  
**Purpose:** Keep the previously-created share visuals and deep guides connected to the new Product Front Door / Design Studio instead of leaving them as one-off chat artifacts.

## Visual rule

The public experience uses managed Design Studio slots rather than hard-coded image files.

Visual precedence:

1. real network-specific cover/media;
2. vertical default;
3. Playground override when inside Playground;
4. built-in fallback when no managed visual exists.

`vertical.<kind>.story.1` through `story.4` are intended for shareable explainers/infographics. They feed the platform Product Story / Guide gallery. This allows Family to have several explanatory images without turning the landing page into a large static image wall.

## Existing share assets to migrate

| Existing asset | Target Design Studio slot | Notes |
| --- | --- | --- |
| `TrustWeave: A Living Family Network.png` | `vertical.family.story.1` | Primary Family share explainer |
| `TrustWeave: One Community, Infinite Possibilities.png` | `vertical.family-association.story.1` | Primary Community / Association share explainer |
| `TrustWeave Residential Community Infographic.png` | `vertical.housing-society.story.1` | Primary Residential share explainer |
| `image-gen-1.png` … `image-gen-4.png` | Review then assign to `vertical.family.story.2` … `story.4` or the correct vertical | Do not guess the vertical from an opaque filename; visually classify before upload |

The original Project/Library files are not repository assets. Upload them through **Launch Control → Design Studio → Vertical defaults** after the platform upload runtime repair is applied. That preserves the exact generated image rather than regenerating an approximation.

## Existing deep-guide PDFs

These remain useful as share packs and should be surfaced from the deployed artifact/document center once their exact binaries are intentionally copied into the release artifact source:

- `TrustWeave_Family_First_Deep_Vertical_Guide.pdf`
- `TrustWeave_MPF_East_Complete_Exploration_Guide.pdf`
- `TrustWeave_Residential_Society_Majestique_Marbella_Flagship_Guide.pdf`
- `TrustWeave_MPF_Federation_Trusted_Networks_Vision_Guide.pdf`

Do not create replacement PDFs merely to satisfy a link. Until the originals are available to the repository/release pipeline, the in-product Guide uses the managed story images and existing deployed HTML artifacts.

## Carousel policy

The front door Product Story carousel is intentionally:

- manual-first;
- no auto-rotation;
- one focused story at a time;
- five representative vertical stories in the primary carousel;
- backed by the same vertical default visual slots used elsewhere;
- supplemented by the Guide visual-story rail when additional `story.2`–`story.4` images exist.

This is product explanation, not decorative animation.
