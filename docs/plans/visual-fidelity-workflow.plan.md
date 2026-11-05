# Implementation Plan: Visual Fidelity Workflow (composition-level translation)

## Intent
CLEAR — Extend `design-contract-system` and `frontend-scaffold` so a visual reference
translates into frontend code with composition-level fidelity (grid structure, alignment,
asymmetry, scroll/floating behavior, per-element typography, image-gen assets), not only
token-level fidelity. Source spec: `docs/research/visual-fidelity-translation-workflow.md`.

## Overview
Token audits pass (19/19 green) while composition drifts, because `design-contract-system`
Phase 1 extracts colors/radius/spacing but never *measures* layout, and `frontend-scaffold`
Phase 5 audits tokens but never compares the render to the reference. All 8 verified user
complaints on the landing-page build were composition-level. This plan adds a measured
**Composition Extraction Protocol**, a **Composition Spec** section in the page contract,
and a **composition fidelity gate** in the scaffold's Phase 5 — as progressive-disclosure
reference files so both SKILL.md bodies stay lean. No new skill (owner decision: extend,
mirroring the `a11y` consolidation ruling). No pixel-diff gate (owner decision: measured
per-section checklist).

## Requirements
- R1 — New `skills/design-contract-system/references/composition-extraction.md`: per-section capture of grid structure, alignment, asymmetry ratio, scroll/floating behavior, per-element typography (size + weight), image treatment, and image-gen prompt spec routed via `experimental_image_generate` (4 Cloudflare Workers AI models).
- R2 — `skills/design-contract-system/templates/page-contract.md` gains a `## 5. Composition Spec` section (layout per section + alignment + behavior + measured typography table + image asset list with prompts).
- R3 — `skills/design-contract-system/SKILL.md` Phase 1 gains one step: extract the composition spec, not only tokens; wire the new reference.
- R4 — `skills/frontend-scaffold/SKILL.md` Phase 5 gains a composition fidelity gate that verifies the per-section composition spec against the running render (dev server + `multimodal-looker` structural comparison), in addition to the canonical token audit file.
- R5 — `skills/design-contract-system/references/anti-slop-rules.md` gains the missing composition rules adapted from stitch taste-design (three-equal-cards ban, single-column < 768px, viewport-height hero) — only what is missing; existing rules are not restated.
- R6 — House style preserved on every edited/created file: `name:` == directory, inline-scalar `description:`, "When to Activate" (SKILL.md), "Anti-Patterns" (SKILL.md), < 500 lines (800 max), `metadata: origin: ECC` on canonical copies.
- R7 — All surfaces stay in sync: Codex mirrors (`.agents/skills/**`), global OpenCode mirrors (`~/.config/opencode/skills/**`), context-registry digest (`manifests/context-packs/skill-triggers@1.json`), catalog, install manifests.
- R8 — `npm test` stays green (baseline 8295/8295).

## Architecture Changes
```
skills/design-contract-system/
├── SKILL.md                        EDIT  Phase 1 step 3 (+ diagram label)
├── references/
│   ├── composition-extraction.md   NEW   per-section capture protocol + multimodal-looker prompt
│   ├── anti-slop-rules.md          EDIT  + "Composition Rules" section
│   └── visual-extraction.md        READ  protocol conventions (no edit)
└── templates/
    └── page-contract.md            EDIT  + "## 5. Composition Spec"

skills/frontend-scaffold/
├── SKILL.md                        EDIT  Phase 0 bullet, Phase 5 gate, Anti-Patterns
└── references/
    └── fidelity-checklist.md       NEW   per-section verification protocol (owner decision: separate file)

.agents/skills/design-contract-system/{SKILL.md,references/,templates/}   MIRROR
.agents/skills/frontend-scaffold/{SKILL.md,references/}                   MIRROR (new dir)
~/.config/opencode/skills/{design-contract-system,frontend-scaffold}/      MIRROR (verbatim)
manifests/context-packs/skill-triggers@1.json                             DIGEST REFRESH
```

Data flow after this change:
```
reference image ──Phase 1──> composition-extraction.md ──> page-contract.md §5 Composition Spec
                                                                      │
dev server + multimodal-looker ──Phase 5──> fidelity-checklist.md <───┘  (PASS/FAIL per section)
```

## Preconditions (do first, before any edit)

1. **Handle the uncommitted prior work.** The tree already contains uncommitted edits to
   `skills/design-contract-system/SKILL.md`, `skills/frontend-scaffold/SKILL.md`, both
   `.agents/` mirrors, and `manifests/context-packs/skill-triggers@1.json` (the prior
   "canonical audit file" work, digest already refreshed to
   `7cafa766…`). Commit it separately (`feat(skills): canonicalize frontend-scaffold audit gate`)
   or stage files explicitly per commit, so this plan's diff stays reviewable.
   - Stage by explicit path (`git add <paths>`), NOT `git add -A`: the tree also carries
     auto-generated noise that must NOT be swept in — modified `.guardian-angel/approvals.json`
     + `.guardian-angel/audit.jsonl` (governance tool rewrites them; revert or leave dirty) and
     untracked `.playwright-mcp/` (browser tooling cache).
   - Why: mixing two unrelated skill changes in one commit breaks the digest-refresh audit trail.
   - Risk: Medium (lost or misattributed work).
2. **Sanitize the research spec for unicode safety.** `scripts/ci/check-unicode-safety.js` is the
   first gate of `npm test` and rejects non-ASCII symbols in `docs/`. The spec
   `docs/research/visual-fidelity-translation-workflow.md` shipped with a `vs` (U+2194) that failed
   the gate — fixed in place during plan review (replaced with "dengan"); re-run
   `node scripts/ci/check-unicode-safety.js` to confirm before proceeding. Any new prose added in
   later phases must stay ASCII-clean.
   - Why: the suite dies before a single test runs; R8 is unreachable otherwise.
   - Risk: Low.
3. **Record the baseline**: `npm test` (expect ~8295 PASS — exact count unverified at review time,
   the success criterion is green *after* the change, not a specific number), `npm run catalog:check`,
   `node tests/ci/codex-skill-surface.test.js`, `node scripts/ci/validate-skill-host-compat.js`.
   - Why: every later gate is a delta against this.
   - Risk: Low.

## Implementation Steps

### Phase 1 — Composition extraction protocol (R1)
1. **Create `skills/design-contract-system/references/composition-extraction.md`** (target 150–220 lines, no frontmatter — matches `visual-extraction.md` / `anti-slop-rules.md`, which are plain markdown).
   - Action: write these sections:
     - `## 1. Why tokens are not enough` — the failure class: token audit green while composition drifts; the 8 verified complaints are all composition-level (hero image-gen background, floating liquid-glass topbar with center logo, font sizes, asymmetric gallery ratio, "Fondasi Rekayasa" section pattern, blog layout + font, centered CTA, footer structure).
     - `## 2. Two passes, never one` — tokens come from `visual-extraction.md`; composition comes from this file. Mixing them produces prose mush.
     - `## 3. Input routing` — image/screenshot → dispatch `multimodal-looker` with the exact prompt block below; HTML export → read computed grid/flex/position from the DOM/CSS instead of estimating.
     - `## 4. Per-section capture schema` — the mandatory table. For **every** section (topbar/nav, hero, gallery, feature sections, blog/news, CTA, footer) capture:
       | Field | Measure | Lands in |
       |---|---|---|
       | `layout` | container `max-w` + side padding; grid columns/rows + gap; span ratio; DOM order | §5.1 |
       | `alignment` | per element: left/center/right/justify; vertical alignment of nav zones | §5.1 |
       | `asymmetry` | measured ratio (e.g. `1 tall : 3 stacked`), expressed as a grid-template string | §5.1 |
       | `behavior` | static / sticky / fixed; scroll-linked (horizontal track); parallax; z-index tier from `STANDARDS.md` §4 ladder; material (liquid-glass vs solid) | §5.3 |
       | `typography` | per element: family role, px size, weight, line-height, tracking, transform (eyebrow uppercase) | §5.2 |
       | `imagery` | full-bleed vs contained, `object-fit`, overlay/scrim, aspect ratio, radius tier | §5.4 |
       | `motion` | enter/exit, scroll-linked, `prefers-reduced-motion` handling | §5.3 |
     - `## 5. The multimodal-looker dispatch` — copy-paste block:
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
     - `## 6. Image asset spec` — for every image the reference shows: asset id, owning section, treatment, aspect, palette constraint, and the generation prompt. Route through `experimental_image_generate` with the 4 catalog models from `frontend-scaffold` Phase 4: `@cf/black-forest-labs/flux-2-klein-9b` (general/UI), `@cf/leonardo/lucid-origin` and `@cf/leonardo/phoenix-1.0` (artistic), `@cf/bytedance/stable-diffusion-xl-lightning` (fast drafts). Prompt composition rules: one image per section, composition variety, single palette (delegate to `imagegen-frontend-web` when operator-local, else apply those rules directly). Verify each accepted asset with `multimodal-looker` and save it into the repo (`assets/` or `public/`) — the experimental tool is not a CDN.
     - `## 7. Grounding rules` — snap radius to the 3 tiers, spacing to 4px, colors to semantic roles; when the reference shows a value outside the house rules, record it as an explicit contract exception with the exact value (it feeds the `frontend-scaffold` Phase 5 whitelist). Never invent a value the reference does not show — mark `UNMEASURED` and stop.
     - `## 8. Handoff mapping` — field → `page-contract.md` §5 subsection → who consumes it.
     - `## 9. Anti-Patterns` — prose-only descriptions ("hero looks modern"), treating a page as one blob, measuring intent instead of pixels, one combined token+composition pass, pixel-diff as the acceptance gate.
   - Why: this is the missing extraction layer; the 8 complaints map 1:1 onto the schema fields.
   - Dependencies: none (new file).
   - Risk: Medium — a schema too coarse reproduces the same drift. Mitigation: the 8-complaint table in §1 is the coverage test; every complaint must map to a field.

### Phase 2 — Page contract gains Composition Spec (R2)
2. **Edit `skills/design-contract-system/templates/page-contract.md`** (47 → ~110 lines).
   - Action:
     - In `## 2. Layout Structure & Bento Grid` add one pointer line: `> Measured per-section composition lives in Section 5; this grid summary is derived from it. Section 5 is the authority.`
     - Append:
       ```
       ## 5. Composition Spec (measured from the visual reference)

       ### 5.1 Per-Section Layout & Alignment
       | Section | Container | Grid / Span Ratio | Alignment | Notes |
       |---|---|---|---|---|
       | `Topbar` | `max-w-7xl px-6` | 3 zones: nav / center logo / actions | logo center, actions right | floating, glass |

       ### 5.2 Measured Typography
       | Element | Family role | Size (px) | Weight | Line-height | Tracking | Transform |
       |---|---|---|---|---|---|---|
       | `HeroH1` | `font-sans` | 64 | 700 | 1.1 | -0.02em | none |

       ### 5.3 Behavior & Motion
       | Section | Position | Scroll behavior | Z tier | Material | Motion |
       |---|---|---|---|---|---|
       | `Topbar` | fixed | none | `z-20` | liquid glass | fade-in on load |

       ### 5.4 Image Asset List
       | Asset ID | Section | Treatment | Aspect | Model | Prompt | Saved path | Status |
       |---|---|---|---|---|---|---|---|
       | `hero-bg` | Hero | full-bleed + scrim | 16:9 | `@cf/black-forest-labs/flux-2-klein-9b` | <prompt> | `public/assets/hero-bg.webp` | pending |

       ### 5.5 Fidelity Checklist (filled by frontend-scaffold Phase 5)
       - [ ] `Topbar` — 3-zone grid, center logo, glass material, `z-20`
       - [ ] …
       ```
     - Do **not** renumber sections 1–4: `frontend-scaffold` Phase 0 cites "Section 3" and "Section 4" by number.
   - Why: the contract must carry measured composition, or Phase 5 has nothing to verify against.
   - Dependencies: Phase 1 (schema fields must match the template's tables exactly).
   - Risk: Low.

### Phase 3 — design-contract-system Phase 1 step (R3)
3. **Edit `skills/design-contract-system/SKILL.md`** (200 → ~212 lines).
   - Action: in `### Phase 1: Ingest & Extract Visual DNA`, after step 1 (the `multimodal-looker` token dispatch) and before step 2 (HTML export), insert:
     ```
     2. **Extract the Composition Spec, not only tokens**:
        Token extraction alone produces contracts that pass audit while drifting from the
        reference. Run `references/composition-extraction.md` over the same image: per-section
        grid structure, alignment, asymmetry ratio, scroll/floating behavior, per-element
        typography (size + weight), image treatment, and the image-gen prompt spec for every
        asset the reference shows. Output lands in the page contract's Section 5.
     ```
     and renumber the existing HTML-export step to 3. Update the workflow diagram line
     `Phase 1: Ingest & Extract DNA` → `Phase 1: Ingest & Extract DNA + Composition`.
   - Why: this is the single step that closes the extraction gap; without it the new reference file is never loaded.
   - Dependencies: Phase 1 (the reference must exist to be cited).
   - Risk: Low.

### Phase 4 — frontend-scaffold fidelity gate (R4)
4. **Create `skills/frontend-scaffold/references/fidelity-checklist.md`** (new directory; target 90–140 lines, plain markdown).
   - Action: write the per-section verification protocol:
     - `## 1. What this gate is` — a measured per-section checklist comparing the render to the contract's §5, run as a **separate layer** after the token audit (OverlayQA pattern: verification is its own layer).
     - `## 2. What this gate is NOT` — not a pixel diff. Pixel diff is brittle to content changes (text, imagery) and cannot express a normative "should". Owner decision, do not revisit.
     - `## 3. Run it` — start the dev server; capture the render at 1440 / 768 / 375; dispatch `multimodal-looker` with **both** the reference image and the screenshots plus the contract's §5 tables; ask for a per-section structural comparison (alignment, grid/span ratio, nav position + material + z tier, per-element font size/weight, image treatment) returning PASS / FAIL / UNMEASURABLE per row with the observed vs expected values.
     - `## 4. Row schema` — one row per section per field: `expected (from §5)` / `observed` / `verdict` / `fix`.
     - `## 5. Verdict rules` — a FAIL means change the render, never the checklist; `UNMEASURABLE` (text not rendered yet, asset pending) is recorded and re-run, not passed; token-audit green does not imply fidelity PASS; the gate is not satisfiable by self-attestation — the `multimodal-looker` dispatch is mandatory evidence.
     - `## 6. Fix loop` — fix, re-capture, re-dispatch; max two loops before escalating to the contract owner (a third failure means the contract's §5 is wrong, not the code).
   - Why: R4's body; keeping it out of SKILL.md is the owner's progressive-disclosure decision.
   - Dependencies: Phase 2 (§5 must exist to compare against).
   - Risk: Medium — a gate that becomes a rubber stamp. Mitigation: §5 verdict rules require dispatch evidence.

5. **Edit `skills/frontend-scaffold/SKILL.md`** (193 → ~212 lines).
   - Action, three edits:
     - `### Phase 0 — Read the Contract`: add as the **first** bullet:
       `- Composition Spec (Section 5) — the measured per-section layout, alignment, typography, and behavior targets. Phase 5 verifies the render against these; they are not optional decoration.`
     - `### Phase 5 — Audit Gate`, after the canonical-audit-file block and before the closing "canonical `design-contract-system` Phase 4 greps" paragraph, insert:
       ```
       **Composition fidelity gate (separate layer, not optional).** The audit file above
       proves token compliance; it says nothing about whether the page looks like the
       reference. Run `references/fidelity-checklist.md`: dev server, capture at
       1440 / 768 / 375, dispatch `multimodal-looker` with the reference plus the screenshots
       against the contract's Section 5, and record PASS / FAIL per section row. Fix the
       render, not the checklist. This gate is a measured checklist, never a pixel diff.
       ```
     - `## Anti-Patterns`: add
       `- **Token-green, composition-drift**: treating a passing token audit as visual fidelity — the observed real-world failure (8 composition complaints under a 19/19 green token audit).`
   - Why: the scaffold is the only phase that sees a running render; the gate has to live where the browser exists.
   - Dependencies: step 4.
   - Risk: Low.

### Phase 5 — Anti-slop composition rules (R5)
6. **Edit `skills/design-contract-system/references/anti-slop-rules.md`** (29 → ~55 lines).
   - Action: append after `## 1. Strictly Banned AI Slop Patterns`:
     ```
     ## 2. Composition Rules (adapted from stitch taste-design)

     1. **No three-equal-cards row**: the default AI grid. Every row of 3+ cards must carry at
        least one asymmetric span, or the contract must state why the content is genuinely
        homogeneous. Reference-faithful asymmetry beats symmetrical tidiness.
     2. **Single column below 768px**: every multi-column composition collapses to one column
        at 375px. Horizontal scroll tracks are mobile-forbidden unless the reference defines one.
     3. **Hero fills a viewport**: use the framework viewport-height utility (`min-h-dvh` in
        Tailwind v4). The arbitrary-bracket form `min-h-[100dvh]` is banned — the geometry
        audit flags every `min-h-[`, and whitelisting it would weaken the rule.
     4. **Touch targets**: 44px minimum on mobile — already specified in
        `templates/standards.md` §3. Cite it; do not restate values here.

     **Precedence**: when the reference itself violates a rule above, the render follows the
     reference and the page contract records an explicit exception with the exact value
     (feeding the Phase 5 whitelist). A rule never loses silently.
     ```
   - Why: closes the taste gap with the minimum new text; items already covered elsewhere are cited, not duplicated.
   - Dependencies: none.
   - Risk: Low.

### Phase 6 — Wiring, mirrors, digest
7. **Confirm no packaging changes are needed** (verified live):
   - `package.json` `files[]` uses per-skill-directory entries (`"skills/design-contract-system/"`, `"skills/frontend-scaffold/"`) → new files inside those dirs are packed automatically. No edit.
   - `manifests/install-modules.json` — module `framework-language` owns both skill dirs; no new skill directories → no edit.
   - `agent.yaml` — both skills already listed (lines 61, 81). No edit.
   - Why: avoids the recurring "new file needs new wiring" mistake.
   - Risk: Low.
8. **Sync Codex mirrors** (frontmatter transform is mandatory):
   - Copy `skills/design-contract-system/references/composition-extraction.md` → `.agents/skills/design-contract-system/references/composition-extraction.md`.
   - Copy edited `references/anti-slop-rules.md` and `templates/page-contract.md` → the same relative paths under `.agents/skills/design-contract-system/` (reference/template files are copied verbatim — no frontmatter).
   - Create `.agents/skills/frontend-scaffold/references/fidelity-checklist.md` (verbatim copy).
   - Regenerate both `.agents/skills/*/SKILL.md` copies from the canonical files with the transform: drop the `metadata:` / `  origin: ECC` block, add `license: MIT`, and unquote the `description:` scalar. (Verified current transform: only those three lines differ.)
   - Why: Codex reads `.agents/skills/`; the frontmatter allowlist (`name`, `description`, `metadata`, `license`, `allowed-tools`) is enforced by `tests/ci/codex-skill-surface.test.js` + `scripts/ci/validate-skill-host-compat.js`.
   - Risk: Medium — mirror drift is currently unguarded by tests; step 10 adds the guard.
9. **Sync global OpenCode mirrors** (verbatim, no transform):
   `rsync -a --delete skills/design-contract-system/ ~/.config/opencode/skills/design-contract-system/` and the same for `frontend-scaffold`.
   - Why: the operator's global harness reads these paths; they were verified byte-identical before this change.
   - Risk: Low. (`--delete` is safe here: the canonical dir is the source of truth and the mirror had no extra files — verified with `diff -r`.)
10. **Refresh the context-registry digest** — editing any SKILL.md or adding any resource file changes the entry `contentDigest`, hence `registryDigest`:
    ```bash
    node -e "
    const fs=require('fs');
    const {loadContextRegistry}=require('./scripts/lib/context-pack-registry');
    const p='manifests/context-packs/skill-triggers@1.json';
    const m=JSON.parse(fs.readFileSync(p,'utf8'));
    m.registryDigest=loadContextRegistry({repoRoot:process.cwd()}).registryDigest;
    m.generatedAt=new Date().toISOString();
    fs.writeFileSync(p, JSON.stringify(m,null,2)+'\n');
    "
    ```
    Then assert equality:
    ```bash
    node -e "
    const fs=require('fs');const {loadContextRegistry}=require('./scripts/lib/context-pack-registry');
    const m=JSON.parse(fs.readFileSync('manifests/context-packs/skill-triggers@1.json','utf8'));
    if(m.registryDigest!==loadContextRegistry({repoRoot:process.cwd()}).registryDigest) throw new Error('digest drift');
    console.log('digest in sync');
    "
    ```
    - Why: `scripts/ci/validate-context-profiles.js` fails on mismatch; this is the recurring trap after every SKILL.md edit (see commit `e181b8c7`).
    - **Do not** use `stableStringify` from the generator — it writes single-line JSON and produces a 310-line diff. Pretty-print with `JSON.stringify(m, null, 2)`; only `registryDigest` + `generatedAt` should change.
    - Risk: Medium.
11. **Catalog**: `npm run catalog:sync` then `npm run catalog:check`.
    - Why: keeps README/AGENTS/plugin counts authoritative. No new skills → counts must not move.
    - Check afterwards: `git status --short docs/tr/AGENTS.md` must be empty (catalog does not cover Turkish; the known drift only appears if counts change, and they must not).
    - Risk: Low.
12. **Add the mirror-drift guard test** — `tests/ci/composition-fidelity-surface.test.js` (auto-discovered by `tests/run-all.js` via `tests/**/*.test.js`; precedent: `tests/ci/mle-workflow-coverage.test.js`):
    - Assert the new files exist in canonical **and** both mirror trees.
    - Assert the `.agents/skills/{design-contract-system,frontend-scaffold}/SKILL.md` copies match their canonical bodies after the frontmatter transform (strip `metadata:`/`origin`, add `license: MIT`, unquote `description`). **Scope the assertion to these two skills only** — the `.agents/skills` surface is heterogeneous: ~6 mirrors are byte-identical/verbatim (a transform-applying assertion would false-fail them), ~23 are clean transform-only, ~25 diverge further (incl. Codex-only skills like `ecc-conventions` with no canonical counterpart). Do not glob `.agents/skills/*`.
    - Assert `page-contract.md` contains `## 5. Composition Spec`, `design-contract-system/SKILL.md` contains `composition-extraction.md`, and `frontend-scaffold/SKILL.md` contains `fidelity-checklist.md`.
    - Why: mirror drift is otherwise silent for the two in-scope skills. Correction from plan review: `tests/skills/module-governance.test.js` already byte-compares one canonicalvsmirror pair, so "no existing test compares" was inaccurate — this guard extends coverage to the two skills this plan touches.
    - Risk: Low. This is the one item beyond the stated deliverables; drop it if the reviewer prefers, accepting unguarded mirrors.

## Testing Strategy

### Unit / static (run in the ECC repo)
| Check | Command | Expect |
|---|---|---|
| Skill house style | `node scripts/ci/validate-skills.js` | no new findings for the two skills |
| Host compat + Codex frontmatter allowlist | `node scripts/ci/validate-skill-host-compat.js` | no new WARN/FAIL for the two skills |
| Codex surface | `node tests/ci/codex-skill-surface.test.js` | 4 passed, 0 failed |
| Catalog parity | `npm run catalog:check` | "Documentation counts match the repository catalog." |
| Command registry | `npm run command-registry:check` | pass |
| Context profiles | `node scripts/ci/validate-context-profiles.js` | pass (digest in sync) |
| Carrier closure | `node scripts/ci/validate-carrier-closure.js` | pass |
| No personal paths | `node scripts/ci/validate-no-personal-paths.js` | pass |
| New drift guard | `node tests/ci/composition-fidelity-surface.test.js` | pass |
| Line caps | `wc -l` on all 5 touched files | all < 500 |
| Full gate | `npm test` | ≥ 8295 baseline, 0 failures |

### Integration
- Registry digest round-trip: the assert in step 10 (live digest == manifest digest).
- Install-manifest validation: `node scripts/ci/validate-install-manifests.js` — proves no packaging wiring was missed by the new files.
- Packed-artifact path: `npm run prepack` (or the packed-artifact test) confirms `skills/design-contract-system/references/composition-extraction.md` and `skills/frontend-scaffold/references/fidelity-checklist.md` ship inside the tarball, since `files[]` is per-skill-directory.

### End-to-end (manual, outside this repo — the real acceptance)
- In the landing-page project, run the Phase 1 protocol against `compro1.webp`, produce `HOME-CONTRACT.md` §5, then run the Phase 5 gate on the dev server.
- Acceptance: each of the 8 original complaints has a §5 row and a PASS verdict with observed-vs-expected numbers (hero image-gen background present; topbar 3-zone floating glass with center logo; per-element font sizes match; gallery asymmetry ratio matches; "Fondasi Rekayasa" section pattern matches; blog layout + font match; CTA center-aligned; footer structure matches).
- This is deliberately manual: ECC's own suite cannot host a third-party reference image, and pixel-diff was ruled out.

## Risks & Mitigations
- **Risk: the new schema is too coarse and drift repeats.**
  Mitigation: §1 of `composition-extraction.md` carries the 8-complaint coverage table; every complaint must map to a schema field. The manual E2E in the landing-page project is the proof.
- **Risk: mirror drift (Codex / global OpenCode) goes unnoticed.**
  Mitigation: step 12's drift-guard test; the frontmatter transform is applied mechanically, not by hand.
- **Risk: registry-digest drift breaks `validate-context-profiles`.**
  Mitigation: step 10's refresh + assert; never use `stableStringify` (310-line diff).
- **Risk: prompt bloat in both SKILL.md files.**
  Mitigation: protocol bodies live in reference files (owner decision 3); SKILL.md grows ~12 lines each; both stay near 210 lines against the 500-line cap.
- **Risk: adopting `min-h-[100dvh]` weakens the geometry audit.**
  Mitigation: the rule is written as `min-h-dvh`; the arbitrary-bracket form is explicitly banned in the same rule so a future editor does not "helpfully" whitelist it.
- **Risk: the fidelity gate degrades into self-attestation.**
  Mitigation: `fidelity-checklist.md` §5 requires the `multimodal-looker` dispatch as evidence, records `UNMEASURABLE` instead of passing it, and caps the fix loop at two iterations before escalating to the contract owner.
- **Risk: anti-slop rules conflict with reference fidelity.**
  Mitigation: an explicit precedence rule — reference wins, exception recorded with the exact value in the contract, feeding the Phase 5 whitelist. No silent rule loss.
- **Risk: uncommitted prior work gets absorbed or lost.**
  Mitigation: precondition 1 commits it separately before any edit.
- **Risk: Turkish docs count drift after `catalog:sync`.**
  Mitigation: no new skills → counts cannot change; step 11 verifies `docs/tr/AGENTS.md` is untouched.

## Success Criteria
- [ ] `skills/design-contract-system/references/composition-extraction.md` exists, < 500 lines, covers grid / alignment / asymmetry / behavior / per-element typography / image treatment + image-gen prompt spec with the 4 Cloudflare model IDs.
- [ ] `skills/design-contract-system/templates/page-contract.md` has `## 5. Composition Spec` with layout+alignment, measured typography, behavior+motion, and image-asset tables; sections 1–4 unchanged in numbering.
- [ ] `skills/design-contract-system/SKILL.md` Phase 1 has the composition step and cites the new reference; workflow diagram updated.
- [ ] `skills/frontend-scaffold/references/fidelity-checklist.md` exists with the run procedure, row schema, and verdict rules (no pixel diff).
- [ ] `skills/frontend-scaffold/SKILL.md` Phase 0 reads Section 5, Phase 5 has the composition fidelity gate, Anti-Patterns names token-green/composition-drift.
- [ ] `skills/design-contract-system/references/anti-slop-rules.md` has the Composition Rules section (three-equal-cards ban, single-column < 768px, `min-h-dvh` hero, touch-target pointer, precedence rule).
- [ ] Codex mirrors transformed correctly; global OpenCode mirrors byte-identical; `tests/ci/codex-skill-surface.test.js` and `validate-skill-host-compat.js` clean for both skills.
- [ ] `manifests/context-packs/skill-triggers@1.json` registryDigest matches `loadContextRegistry()`; diff limited to `registryDigest` + `generatedAt`.
- [ ] `npm run catalog:check` passes; `docs/tr/AGENTS.md` unchanged; no `package.json` / `manifests/install-modules.json` / `agent.yaml` diff.
- [ ] `npm test` green (≥ 8295 baseline plus the new drift-guard test).
- [ ] Manual E2E in the landing-page project: all 8 original complaints have a §5 row with a PASS verdict.
