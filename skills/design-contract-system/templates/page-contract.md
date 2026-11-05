# [FEATURE_OR_PAGE_NAME] Component & View Contract

> **Contract Authority**: Before writing or modifying TSX/CSS for this view, confirm implementation adheres to the specs below.

---

## 1. View Purpose & User Journey
- **Route**: `/[route-path]`
- **Primary Goal**: [1-sentence statement of what the user achieves here]
- **User Roles Allowed**: [Admin, Operator, Viewer, etc.]

---

## 2. Layout Structure & Bento Grid
- **Desktop Grid (1440px+)**: [e.g. 12-column Bento grid with 4-col KPI row and 8-col / 4-col analytics split]
- **Tablet Grid (768px - 1024px)**: [e.g. 2-column stacked layout]
- **Mobile Grid (375px - 640px)**: [e.g. 1-column linear vertical scroll, fixed bottom CTA or drawer]

> Measured per-section composition lives in Section 5; this grid summary is derived from it. Section 5 is the authority.

---

## 3. Component Hierarchy & Semantic Tokens
List every component rendered on this view and the exact tokens it binds to:

| Component ID | Semantic Role | Background Token | Text Token | Radius Tier |
|---|---|---|---|---|
| `HeaderBar` | View header | `bg-surface` | `text-text-strong` | `rounded-none` |
| `SummaryCard` | Metric summary | `bg-surface` | `text-text-strong` | `rounded-xl` |
| `FilterTrigger`| Dropdown control | `bg-surface` | `text-text-default` | `rounded-lg` |
| `PrimaryAction`| Main CTA button | `bg-primary` | `text-primary-fg` | `rounded-lg` |
| `DataTable` | Record list | `bg-surface` | `text-text-default` | `rounded-xl` |

---

## 4. State Matrix Implementation for this View

Every view must explicitly verify its 10 states:

- [ ] **1. Loading Skeleton**: Skeletons match exact card/table row height.
- [ ] **2. Empty State**: Custom empty illustration/icon with call-to-action.
- [ ] **3. No Search Result**: Search input retains query; "Clear search" button active.
- [ ] **4. Error State**: Inline alert with retry button; navigation remains intact.
- [ ] **5. No Internet**: Offline notification banner rendered.
- [ ] **6. Slow Network**: Optimistic updates or top loading bar after 1500ms.
- [ ] **7. Permission Denied**: Restricted access banner with contact admin prompt.
- [ ] **8. Session Expired**: Re-auth modal pops without discarding view inputs.
- [ ] **9. Form Validation**: Field errors positioned directly under inputs with `text-danger-fg`.
- [ ] **10. Success State**: Action confirmation toast appears with auto-dismiss.

---

## 5. Composition Spec (measured from the visual reference)

Filled by `design-contract-system` Phase 1 via `references/composition-extraction.md`.
Numbers, not adjectives. `UNMEASURED` stops the handoff for that field — ask the
contract owner, never invent. Verified by `frontend-scaffold` Phase 5.

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
