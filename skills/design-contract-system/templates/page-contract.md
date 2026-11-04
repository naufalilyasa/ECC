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
