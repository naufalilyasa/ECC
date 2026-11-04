# Frontend Workflow Playbook for Nexvora (ECC + OpenCode)

## Problem
A solo developer building the Nexvora commercial SaaS wastes hours through trial-and-error across hundreds of installed AI skills and commands, frequently producing generic "AI-slop" aesthetics or inadvertently breaking working components. Without a deterministic, case-based decision matrix, refactoring existing UI into stunning, enterprise-grade interfaces remains high-risk, unpredictable, and slow.

## Evidence
- Observed developer feedback: "waktu berjam jam karena salah pilih workflow" (hours wasted due to incorrect workflow selection).
- Documented hesitation: fear of invoking the wrong command/skill and regressing or corrupting existing working UI.
- Commercial imperative: Nexvora requires an original, premium, enterprise-grade aesthetic to be viable for customer acquisition.

## Users
- **Primary**: Solo founder and frontend developer of Nexvora refactoring and elevating existing web interfaces.
- **Not for**: Backend-only service developers, native mobile engineers (Swift/Kotlin), or projects with dedicated human design teams providing pixel-perfect Figma specs.

## Hypothesis
We believe a **Case-Based Frontend Workflow Playbook** mapping specific UI scenarios directly to exact ECC slash commands, local skills, and sequential phase gates will **eliminate tool selection trial-and-error and prevent visual/functional regressions** for **Nexvora's solo developer**.
We'll know we're right when **any target UI screen in Nexvora can be audited, redesigned, and verified to enterprise standard in under 2 hours without workflow guesswork or component rollback**.

## Success Metrics
| Metric | Target | How measured |
|---|---|---|
| Workflow Decision Time | < 2 minutes | Time taken to identify the exact skill sequence for any specific frontend scenario |
| AI-Slop Elimination | 0 generic slop signals | Visual audit passing zero-slop checks (no gratuitous purple gradients, unconsidered card nesting, or default sans stacks) |
| Functional Stability | 0 broken interactions | 100% of interactive user paths passing rendered state validation post-refactor |
| Execution Speed | < 2 hours / screen | Wall-clock time from audit to verified pull request |

## Scope
**MVP** — A comprehensive, executable Markdown playbook covering 5 critical frontend cases utilizing exclusively the tools and skills already installed globally on this machine:
1. **Case A (Anti-Slop Elevation)**: Transforming working but generic/AI-slop UI into bespoke, enterprise-quality presentation.
2. **Case B (Enterprise Data Density)**: Implementing complex, dense components (multi-filter data tables, layered modals, analytics boards) without clutter.
3. **Case C (Accessibility & Cross-Device Hardening)**: Remediation for contrast, keyboard navigation, focus states, and narrow/wide viewport responsiveness.
4. **Case D (Micro-Interactions & Subdued Motion)**: Adding subtle, performant transitions (springs, state changes, toasts) without distracting visual noise.
5. **Case E (Design Token Harmonization)**: Extracting and enforcing a cohesive rhythm for spacing, typography, borders, and color tokens across fragmented components.

Each case must specify:
- Pre-conditions & Anti-Patterns to avoid
- Phase-by-phase execution sequence
- Exact skill and command pairing per phase
- Stop conditions & rendered verification gates

**Out of scope**
- Backend service logic, database schemas, and API endpoint implementation (handled by backend workflows).
- CI/CD deployment pipelines, Docker configurations, and infrastructure provisioning.
- Brand asset generation (3D modeling, logo creation, marketing vector illustration).

## Delivery Milestones
<!-- Business outcomes, not engineering tasks. /plan turns each into a plan. -->
<!-- Status: pending | in-progress | complete -->

| # | Milestone | Outcome | Status | Plan |
|---|---|---|---|---|
| 1 | Playbook Architecture & Decision Matrix | Developer can identify their frontend case and immediately retrieve the matching phase flow within 2 minutes | complete | docs/playbooks/frontend-workflow-playbook.md |
| 2 | Five Case-Specific Execution Blueprints | Developer can execute Cases A through E step-by-step using verified local skills without guesswork | complete | docs/playbooks/frontend-workflow-playbook.md |
| 3 | Enterprise Quality & Render-Gate Protocol | Developer has a mandatory verification checklist and evidence script protocol before any code commit | complete | docs/playbooks/frontend-workflow-playbook.md |

## Open Questions
- [ ] What specific CSS approach does Nexvora standardize on (Tailwind CSS, CSS Modules, or Styled Components) that should anchor the code-level examples?
- [ ] Are there specific enterprise reference benchmarks (e.g., Linear, Stripe, Vercel, Raycast) that define the visual target for Nexvora?

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Playbook suggests skills or agents not installed on the machine | Medium | High | Restrict references strictly to the 210 local skills and available OpenCode agents |
| Model falls back to generative rewriting instead of surgical refactoring | High | High | Enforce Phase 1 (Audit) and Phase 3 (Plan approval) as hard non-coding gates |
| Developer skips visual verification and relies solely on unit tests | High | High | Mandate the rendered finish gate (`check-evidence.js` / browser snapshot) in every case blueprint |

---
*Status: DELIVERED — Playbook available at `~/.config/opencode/FRONTEND-WORKFLOW-PLAYBOOK.md` and `docs/playbooks/frontend-workflow-playbook.md`.*
