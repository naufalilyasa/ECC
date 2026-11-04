# Implementation Plan: Design Contract System Skill (`design-contract-system`)

## Intent
CLEAR - Implement a new skill `skills/design-contract-system/` that turns visual references (HTML export, UI screenshot, or mockup URL) into a modular, anti-slop design contract system (`DESIGN.md`, `docs/design/BRAND.md`, `STANDARDS.md`, `THEME.md`, `TOKEN-MAP.md`, `TYPOGRAPHY-MAP.md`, and per-page `<FEATURE>-CONTRACT.md`) with enforced 10 system states, based on the battle-tested Nexvora/Reiwa workflow. Vision inputs are inspected via the `multimodal-looker` agent.

## Overview
This skill operationalizes the human UI/UX designer workflow proven in Nexvora and Reiwa. It extracts design DNA from references using `multimodal-looker` (for images/screenshots) or AST/DOM parsing (for HTML exports), establishes semantic role-based tokens (colors, typography, 3 radius tiers, 4px spacing rhythm), defines a strict 10-state system matrix, and produces modular markdown contracts so subsequent AI agents generate consistent, pixel-accurate, anti-slop interfaces without context bloating.

## Requirements
- `skills/design-contract-system/SKILL.md` conforms to ECC standards (valid frontmatter, under 500 lines, clear trigger rules).
- Extracted templates stored in `skills/design-contract-system/templates/` for progressive disclosure.
- Integration with `multimodal-looker` agent for inspecting screenshots/images and extracting color tokens, radius tiers, typography hierarchy, and spacing scales.
- 10 mandatory system states enforced in every design contract: empty state, loading skeleton, error state, no internet, slow network, no search result, permission denied, session expired, form validation, success state.
- Surface wiring: registered in `agent.yaml`, `manifests/install-modules.json`, Codex subset `.agents/skills/design-contract-system/` (`agents/openai.yaml`), Cursor subset `.cursor/skills/design-contract-system/`, and global OpenCode `~/.config/opencode/skills/design-contract-system/`.
- Full verification: `npm test` gauntlet passes cleanly.

## Architecture & File Structure

```
skills/design-contract-system/
├── SKILL.md                          # Primary workflow: Analyze -> Generate -> Enforce/Verify
├── templates/
│   ├── root-design.md                # Template for project root DESIGN.md routing table
│   ├── brand.md                      # Template for docs/design/BRAND.md
│   ├── standards.md                  # Template for docs/design/STANDARDS.md (3 radius tiers, 4px grid)
│   ├── theme.md                      # Template for docs/design/THEME.md (dual-mode token pairing)
│   ├── token-map.md                  # Template for docs/design/TOKEN-MAP.md (role-based token table)
│   ├── typography-map.md             # Template for docs/design/TYPOGRAPHY-MAP.md (sans vs mono rules)
│   ├── states-matrix.md              # Template for docs/design/STATES-MATRIX.md (10 required UI states)
│   └── page-contract.md              # Template for docs/design/contracts/[PAGE]-CONTRACT.md
└── references/
    ├── visual-extraction.md          # Multi-modal visual inspection rubrics with multimodal-looker
    └── anti-slop-rules.md            # Banned AI patterns (gradients, arbitrary hex, float radiuses)
```

## Implementation Phases

### Phase 0: Golden Architecture Extraction (Nexvora Blueprint)
- Extract reference sections and rules from the local project design archive:
  - 3-tier corner radius (`rounded-lg: 8px`, `rounded-xl: 12px`, `rounded-2xl: 16px`, `rounded-full: capsules`)
  - 4px spacing scale (multiples of 4px; ban odd/fractional paddings)
  - Typography division: Sans with `tabular-nums` for calculable business metrics vs Mono for SKU/ID identifiers
  - Role-based token nomenclature: `text-strong`, `primary`, `surface`, `border-subtle` (no raw hex)
  - The 10 mandatory UI/UX system states

### Phase 1: Create Skill & Modular Templates
1. Write `skills/design-contract-system/templates/*.md`
2. Write `skills/design-contract-system/references/*.md`
3. Write `skills/design-contract-system/SKILL.md` (compact orchestration, under 500 lines)

### Phase 2: Surface Wiring & Cross-Harness Parity
1. Add `"skills/design-contract-system/"` to `files` array in `package.json`
2. Add to `agent.yaml`
3. Add to `manifests/install-modules.json`
4. Add to `.agents/skills/design-contract-system/` with Codex-clean frontmatter + create `.agents/skills/design-contract-system/agents/openai.yaml`
5. Add to `.cursor/skills/design-contract-system/`
6. Deploy to global `~/.config/opencode/skills/design-contract-system/`
7. Run `npm run catalog:sync`

### Phase 3: Automated Validation & Testing
1. Run `node scripts/ci/validate-skills.js`
2. Run `node scripts/ci/validate-skill-host-compat.js`
3. Run `npm test`

## Testing & Verification
- Unit & manifest validation: `npm test` returns 0 errors.
- Visual inspection test: verified live via `multimodal-looker` subagent against Nexvora screenshot.
- Structural parity: output format matches Nexvora design system docs.
