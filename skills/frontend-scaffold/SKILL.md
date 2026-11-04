---
name: frontend-scaffold
description: Turn a frozen design contract (DESIGN.md + docs/design/ + page CONTRACT.md) into a running frontend skeleton — project structure, wired design tokens, page shells with all 10 system states, and correct routing for image generation and animation. Use when a design-contract-system contract exists and implementation must start, or when scaffolding a new frontend that must stay consistent with an established design system.
metadata:
  origin: ECC
---

# Frontend Scaffold

Turn frozen design contracts into a running skeleton. The contract decides
*what* is built; this skill builds the smallest structure that satisfies it —
tokens wired, page shells generated, all 10 system states present, assets and
animation routed correctly.

## When to Activate

- `DESIGN.md` + `docs/design/` contracts exist (from `design-contract-system`) and implementation starts
- Scaffolding a new page or feature that must consume an existing page contract
- Adding image generation or animation to a frontend and needing the correct routing
- A skeleton exists but drifted from the contract (re-scaffold the affected files)

## Inputs (fail-closed gate)

Required on disk before any scaffolding:

1. `DESIGN.md` at project root — routing index to the 6 `docs/design/` files
2. `docs/design/TOKEN-MAP.md` + `docs/design/STATES-MATRIX.md` — the two files this skill consumes most
3. `docs/design/contracts/[FEATURE]-CONTRACT.md` for the page being built

If any is missing, STOP — run `design-contract-system` first. Never invent
tokens or states that the contract does not declare. The contract is a
read-only input; this skill generates code, it does not redesign.

## Workflow

### Phase 0 — Read the Contract

Read `DESIGN.md`, then the page contract. Extract:
- Component-to-token binding table (Section 3) — what to generate
- State matrix (Section 4) — which of the 10 states are in-scope vs `OUT_OF_SCOPE`
- Authorized roles and responsive breakpoints (1440 / 768 / 375)

### Phase 1 — Project Structure

Detect the framework before generating:

| Signal | Structure |
|--------|-----------|
| `next` in deps | Next.js App Router: `app/(group)/[feature]/page.tsx`, `loading.tsx`, `error.tsx` |
| `vite` + `react` in deps | `src/routes/[feature]/` + route-level `Suspense`/error boundaries |
| Greenfield full-stack SaaS | If a `saas-scaffolder` skill is available in your harness (operator-local, not repo-shipped), delegate the boilerplate to it, then return here for contract-driven pages |

Never mix conventions from both structures.

### Phase 2 — Wire Tokens

Copy the token architecture from `docs/design/THEME.md` into the project's
`globals.css` verbatim (both `html[data-theme="light"]` and `[data-theme="dark"]`
blocks). Rules:
- CSS custom properties are the only source of color values; components reference `var(--color-*)` or semantic Tailwind classes (`bg-surface`, `text-text-strong`)
- Exactly 3 radius tiers: `rounded-lg` (8px controls), `rounded-xl` (12px cards), `rounded-2xl` (16px modals); `rounded-full` only for badges/avatars/progress
- 4px spacing grid only (`p-1`…`p-12`); no `p-[13px]`, no `gap-1.5`
- Metrics and money: `font-sans tabular-nums` — never `font-mono`
- A token missing from the contract is a contract gap, not a license to invent — flag it and stop

### Phase 3 — Generate Page Shells

For each row of the contract's component table, generate one component file.
For each in-scope state in the contract's state matrix, generate its component.
Canonical 10 states (names match `page-contract.md`):

1. `Loading Skeleton` — aspect-ratio-matched skeleton grid
2. `Empty State` — first-run graphic + primary onboarding action
3. `No Search Result` — "clear filters" secondary state
4. `Error State` — component-level retry + human-readable message
5. `No Internet` — offline banner + cached-data timestamp
6. `Slow Network` — stale-data indicator without unmounting content
7. `Permission Denied` — access-restricted card
8. `Session Expired` — re-auth dialog trigger
9. `Form Validation` — inline field errors + border tokens
10. `Success State` — ephemeral toast/confirmation

States the contract marks `OUT_OF_SCOPE` are NOT generated — implement only
what the view actually has (e.g. a read-only dashboard skips Form Validation).
Data fetching uses `useQuery`-style hooks with explicit loading/error branches
(`frontend-patterns`); every branch renders a state component, never a bare
spinner.

### Phase 4 — Route Assets & Animation

**Image generation** (default path — no new keys):
- Use the harness tool `experimental_image_generate`
- Available models (catalog, all `cloudflare-workers-ai`): `@cf/black-forest-labs/flux-2-klein-9b` (general/UI reference), `@cf/leonardo/lucid-origin` and `@cf/leonardo/phoenix-1.0` (artistic/illustrative), `@cf/bytedance/stable-diffusion-xl-lightning` (fast drafts)
- Direction skills `imagegen-frontend-web` / `imagegen-frontend-mobile` (operator-local, not repo-shipped) govern prompt composition when available: one image per section, composition variety, single palette. If absent, compose prompts directly with those rules
- Verify output with `multimodal-looker`; save accepted images into the repo (`assets/` or `public/`) — the experimental tool is not a production CDN
- Programmatic/batch generation (fal.ai, OpenAI, Google AI Studio) is a separate opt-in requiring an owner-supplied key — not part of the default path

**Animation routing — by deliverable, not by preference:**

| Deliverable | Tool | Skill |
|-------------|------|-------|
| In-app UI animation (enter/exit, gestures, layout, scroll-linked) | `motion/react` | `motion-foundations` → `motion-patterns` → `motion-advanced` |
| Rendered video file (MP4 — demos, social, hero loops) | Remotion | `remotion-video-creation` |
| Presentation decks | — | `frontend-slides` |

Default is `motion/react`: hardware-accelerated, MIT license, 60/120fps while
the JS thread is busy. Reach for Remotion only when the deliverable is a video
file. GSAP is not recommended for general use (Webflow-owned license, banned
in Webflow competitors).

### Phase 5 — Audit Gate

Run the canonical `design-contract-system` Phase 4 greps on the staged diff:

```bash
git diff --staged | grep -E "bg-\[#|text-\[#|border-\[#|fill-\[#" && echo "VIOLATION: Hardcoded hex" || echo "OK"
git diff --staged | grep -E "rounded-sm|rounded-md|rounded-3xl|rounded-\[" && echo "VIOLATION: Invalid radius" || echo "OK"
git diff --staged | grep -E "gap-1\.5|gap-2\.5|p-3\.5|m-\[|px-\[|pt-\[|w-\[|h-\[" && echo "VIOLATION: Non-4px spacing" || echo "OK"
```

Then verify every in-scope state from the contract's Section 4 has a component,
and every generated component consumes tokens (no raw colors anywhere).

The greps above are the canonical `design-contract-system` Phase 4 set,
extended with `px-[`, `pt-[`, `w-[`, `h-[` for stricter coverage.

## Anti-Patterns

- **Inventing tokens**: a color/spacing value that is not in `TOKEN-MAP.md`/`THEME.md` — flag the contract gap instead
- **Happy-path shells**: page components without their state components — the single most common scaffold failure
- **Wrong animation tool**: Remotion for a hover animation, or `motion/react` for a rendered marketing video
- **Contract drift**: regenerating a page by hand after the contract changed — re-scaffold from the contract
- **Skipping the audit gate**: the three greps exist because hex/radius/spacing violations are invisible in review screenshots
- **Treating the image tool as production storage**: generated images must land in the repo

## Related Skills

- `design-contract-system` — upstream: produces the contracts this skill consumes
- `frontend-patterns` — component composition, hooks, data fetching
- `a11y` — WCAG 2.2 AA: contrast, keyboard, screen-reader semantics on every state component
- `frontend-design-direction` — aesthetic direction when no contract exists yet
- `motion-foundations` / `motion-patterns` / `motion-advanced` — in-app animation
- `remotion-video-creation` — video-file deliverables
- `imagegen-frontend-web` / `imagegen-frontend-mobile` — image direction (operator-local, when present in the harness)
- `multimodal-looker` — dispatch this subagent to visually verify generated assets (it is an agent, not a skill)
- `saas-scaffolder` — operator-local full-stack boilerplate skill, when present in the harness
