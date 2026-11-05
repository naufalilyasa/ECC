# Composition Extraction Protocol

Companion to `visual-extraction.md`. That file extracts **tokens** (color, radius,
spacing, typography families). This file extracts **composition** — the measured
layout structure that makes a page look like its reference. Run both, separately,
on every visual reference.

## 1. Why tokens are not enough

The failure class this protocol exists for: a build passes a 19/19 green token
audit while drifting from the reference in every way the audit cannot see.
Verified real-world case (landing page against `compro1.webp`) — all 8 user
complaints were composition-level:

| # | Complaint | Schema field that would have caught it |
|---|-----------|----------------------------------------|
| 1 | Hero has no image-gen background | `imagery` (full-bleed treatment) + §6 asset spec |
| 2 | Topbar not a floating liquid-glass pill; logo must be centered; search + Contact Us right | `layout` (3-zone grid) + `behavior` (fixed + material) |
| 3 | Font sizes differ from reference | `typography` (per-element px + weight) |
| 4 | Asymmetric gallery layout wrong | `asymmetry` (measured span ratio) |
| 5 | "Fondasi Rekayasa" section pattern wrong | `layout` + `behavior` (scroll track) |
| 6 | Blog/news layout and font wrong | `layout` + `typography` |
| 7 | CTA section must be center-aligned | `alignment` (per element) |
| 8 | Footer structure not similar | `layout` (column structure + rows) |

If a future complaint cannot be mapped to a schema field below, the schema is
too coarse — extend it before shipping the contract.

## 2. Two passes, never one

- **Token pass** — `visual-extraction.md`: colors, radius tiers, spacing scale,
  font families. Produces THEME / TOKEN-MAP / STANDARDS inputs.
- **Composition pass** — this file: grid, alignment, asymmetry, behavior,
  measured typography, imagery, motion. Produces the page contract's Section 5.

Mixing both in one prompt produces prose mush ("a modern hero with nice
spacing"). Keep the dispatches separate; keep the outputs in separate sections.

## 3. Input routing

| Input | Route |
|---|---|
| Image / screenshot (PNG, WebP, JPG) | Dispatch `multimodal-looker` with the prompt block in §5 |
| HTML export (v0, Lovable, Stitch, saved page) | Read computed `display`, `grid-template-*`, `flex-*`, `position`, and used font sizes from the DOM/CSS instead of estimating from pixels |
| Live site | Browser screenshot at 1440 / 768 / 375, then treat as images |
| Figma | No direct access in this harness — export section screenshots and treat as images |

## 4. Per-section capture schema

For **every** section, top to bottom: topbar/nav, hero, each gallery or feature
section, blog/news, CTA, footer. No section is "obvious" — the drift always
hides in the section nobody measured.

| Field | Measure | Lands in |
|---|---|---|
| `layout` | container `max-w` + side padding in px; grid columns/rows + gap; span ratio; DOM order | §5.1 |
| `alignment` | per element: left / center / right / justify; vertical alignment of nav zones | §5.1 |
| `asymmetry` | measured ratio (e.g. `1 tall : 3 stacked`) expressed as a grid-template string | §5.1 |
| `behavior` | static / sticky / fixed; scroll-linked (horizontal track); parallax; z-index tier from `templates/standards.md` §4 ladder; material (liquid glass vs solid) | §5.3 |
| `typography` | per element: family role, px size, weight, line-height, tracking, transform (eyebrow uppercase) | §5.2 |
| `imagery` | full-bleed vs contained, `object-fit`, overlay/scrim, aspect ratio, radius tier | §5.4 |
| `motion` | enter/exit, scroll-linked, `prefers-reduced-motion` handling | §5.3 |

Rules while capturing:

- Numbers, not adjectives. "64px 700" — never "big bold headline".
- Anything the reference does not show is marked `UNMEASURED` and stops the
  handoff for that field (ask the contract owner; never invent).
- One row per element for typography; one row per section for the rest.

## 5. The multimodal-looker dispatch

Copy-paste block (adjust `<path>`):

```
subagent(agent="multimodal-looker", description="Extract composition spec from reference")
"Read the image at `<path>`. For EACH section top-to-bottom (nav, hero, gallery,
each feature section, blog/news, CTA, footer) report: (1) container width and side
padding in px; (2) grid columns/rows, gap, and span ratio as a ratio; (3) per-element
horizontal alignment; (4) sticky/fixed/scroll-linked behavior and any glass material;
(5) a typography table — element, size px, weight, line-height, letter-spacing,
uppercase?; (6) image treatment (full-bleed/contained, object-fit, overlay, aspect,
radius). Give measured numbers, not adjectives. Mark anything you cannot measure
UNMEASURED. Output structured markdown."
```

`multimodal-looker` is an agent, not a skill — dispatch it via `subagent()`.

## 6. Image asset spec

For every image the reference shows, one row in the page contract's §5.4:

| Field | Content |
|---|---|
| Asset ID | kebab-case, e.g. `hero-bg` |
| Owning section | e.g. `Hero` |
| Treatment | full-bleed + scrim / contained card / avatar |
| Aspect | e.g. `16:9` |
| Palette constraint | one palette across all assets (from THEME.md) |
| Model | from the catalog below |
| Prompt | one image per section; composition variety (never the same layout twice); no text inside the image unless the reference shows text |
| Saved path | inside the repo (`assets/` or `public/`) — the experimental tool is not a CDN |
| Status | pending / generated / verified |

Catalog models (via `experimental_image_generate`):

- `@cf/black-forest-labs/flux-2-klein-9b` — general / UI reference (default)
- `@cf/leonardo/lucid-origin`, `@cf/leonardo/phoenix-1.0` — artistic
- `@cf/bytedance/stable-diffusion-xl-lightning` — fast drafts

If the operator-local `imagegen-frontend-web` / `imagegen-frontend-mobile`
direction skills are available in the harness, delegate prompt composition to
them; otherwise apply their rules directly (one standalone horizontal image per
section, varied composition, single palette). Verify every accepted asset with
`multimodal-looker` before wiring it into the page.

## 7. Grounding rules

- Snap measured radius to the 3 house tiers (`rounded-lg` 8px controls /
  `rounded-xl` 12px cards / `rounded-2xl` 16px modals; `rounded-full` for pills).
- Snap spacing to the 4px grid.
- Snap colors to semantic roles (never raw hex in components).
- When the reference shows a value outside the house rules, record it as an
  explicit contract exception with the exact value — it feeds the
  `frontend-scaffold` Phase 5 whitelist (per-exact-value, never prefix).
- Never invent a value the reference does not show. `UNMEASURED` and stop.

## 8. Handoff mapping

| Field | Lands in | Consumed by |
|---|---|---|
| `layout`, `alignment`, `asymmetry` | `page-contract.md` §5.1 | scaffold Phase 3 (page shells) |
| `typography` | `page-contract.md` §5.2 | scaffold Phase 3 (type classes) |
| `behavior`, `motion` | `page-contract.md` §5.3 | scaffold Phase 3/4 (nav, scroll tracks, animation routing) |
| `imagery` + asset spec | `page-contract.md` §5.4 | scaffold Phase 4 (image routing) |
| all of the above | `page-contract.md` §5.5 checklist rows | scaffold Phase 5 (fidelity gate) |

## 9. Anti-Patterns

- Prose-only descriptions ("hero looks modern", "clean layout") — unverifiable,
  and the exact failure mode this protocol replaces.
- Treating a page as one blob — per-section capture is mandatory; drift hides in
  the unmeasured section.
- Measuring intent instead of pixels — "should feel airy" is not a measurement.
- One combined token + composition pass — see §2.
- Pixel-diff as the acceptance gate — brittle to content changes and cannot
  express a normative "should". The fidelity checklist (frontend-scaffold
  Phase 5) is the gate.
- Whitelisting by prefix in Phase 5 — per-exact-value only, or the geometry
  audit loses its teeth.
