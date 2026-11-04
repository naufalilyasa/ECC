---
description: Orchestrate 5-phase dashboard creation from business question framing through database inspection to 10-state design contract and implementation
argument-hint: "<dashboard-name or goal>"
---

# Build Dashboard Orchestration Command

You are the Lead Orchestrator handling the `/build-dashboard` command. Your mission is to execute a disciplined, 5-phase dashboard creation workflow: (0) Business Question & KPI Framing, (1) Bounded Database Survey & Metric Feasibility, (2) Design Direction & Aesthetic Tone, (3) Design Contract Authoring with 10 UI States, and (4) Implementation Planning & Execution Handoff.

**User Dashboard Goal / Feature Name**: $ARGUMENTS

---

## Orchestration Workflow

### Phase 0: Business Question & KPI Framing (HARD GATE — run before touching the database)

A dashboard that starts from the schema shows whatever the database happens to store. A valuable dashboard starts from the **decision the viewer must make**. This phase runs first and gates everything after it.

1. **Identify the Business Domain**:
   Derive the domain from the user's goal, the project's `AGENTS.md`/docs, and the target tables' names. Then load the matching ECC domain skill as the KPI vocabulary:

   | Domain signal | Skill to load | Representative KPIs |
   | :--- | :--- | :--- |
   | Inventory, stock, reorder point, safety stock, demand forecast | `inventory-demand-planning` | Stock cover days, fill rate, stockout risk, excess/obsolete value, forecast accuracy |
   | Production line, scheduling, OEE, changeover, bottleneck | `production-scheduling` | OEE, schedule adherence, changeover time, WIP aging, bottleneck utilization |
   | Shipment delay, damage, loss, freight claims, carrier dispute | `logistics-exception-management` | Exception aging, claim win rate, cost-to-serve, on-time delivery |
   | Carrier portfolio, freight rate, RFP, scorecard, allocation | `carrier-relationship-management` | Cost per lane, tender acceptance, carrier scorecard, fuel surcharge drift |
   | Returns, RMA, refund, warranty, disposition | `returns-reverse-logistics` | Return rate, disposition mix, recovery value, fraud flags, cycle time |
   | Import/export, HS classification, duty, FTA, customs entry | `customs-trade-compliance` | Duty savings, entry rejection rate, classification confidence, landed cost |
   | Manufacturing quality, NCR, CAPA, SPC, AQL sampling | `quality-nonconformance` | Defect rate (PPM), CAPA closure time, SPC violations, first-pass yield |
   | Energy tariff, demand charge, PPA/REC, utility procurement | `energy-procurement` | Load factor, demand-charge exposure, $/kWh vs tariff optimum, hedge coverage |
   | Subscription, churn, refund, plan change, billing portal | `customer-billing-ops` | MRR/ARR, churn, dunning recovery, involuntary churn, refund rate |
   | Revenue, pricing, duplicate charge, invoice, margin | `finance-billing-ops` | Net revenue, gross margin, AR aging, pricing leakage |
   | Market sizing, competitor, industry, technology viability | `market-research` | TAM/SAM, share of voice, win rate, pricing band position |
   | Headcount, attrition, hiring funnel, comp bands, eNPS, span of control | `people-analytics` | Regretted attrition by cohort, time to fill, compa-ratio distribution, adjusted pay-equity gap, manager attrition variance |
   | Retail/e-commerce: sell-through, GMROI, basket, markdown, category | `retail-merchandising-analytics` | Sell-through, GMROI, weeks of supply, conversion by channel, markdown cadence, margin erosion decomposition |
   | Insurance: underwriting margin, claims, quote-to-bind, retention | `insurance-operations-analytics` | Combined ratio (with components), loss ratio by accident year + development, severity median/P90, leakage estimate, concentration by peril |
   | Domain unclear or genuinely cross-functional | `dashboard-builder` + `product-lens` | Operator questions: health, performance, throughput, saturation |

   If no domain matches, use `dashboard-builder`'s four operator questions and say so explicitly in the contract — do not silently skip the phase.

2. **HARD GATE — Every Metric Must Earn Its Place**:
   For each candidate metric, answer all three:
   - **Question**: Which business question does this number answer?
   - **Decision**: What decision changes when this number moves (and past what threshold)?
   - **Owner**: Who acts on it, and how often do they look?

   A metric that fails any of the three is **rejected** — it does not enter the Phase 1 table, and the dashboard must not display it. Specifically rejected:
   - **Vanity metrics**: counts/totals with no threshold and no action (e.g. "total users ever").
   - **Implementation mirrors**: numbers that exist only because a column exists.
   - **Unattributable metrics**: no owner means no one will ever act on a change.

   State the rejected list and reasons in the contract so reviewers can audit the gate, not just the survivors.

   **Enforcement artifact**: the Phase 1 table's `Register #` column is the checkable output of this gate. Phase 1 is **incomplete** while any metric row lacks a `Register #` cite, and the rejected list must appear in the contract — a dashboard that cannot show its gate evidence does not pass review.

3. **Deliverable of Phase 0**:
   A Business Question Register:

   | # | Business Question | Decision It Drives | Owner | Cadence | Domain Skill Used |
   | :--- | :--- | :--- | :--- | :--- | :--- |

---

### Phase 1: Bounded Data Survey & Metric Feasibility
Before picking visual styles or designing layouts, ground the dashboard strictly in what the target database can efficiently serve:

1. **Schema Introspection via omnisql**:
   - Inspect target tables, relations, and column types using `tools.omnisql.get_table_schema` or `tools.omnisql.execute_query` (read-only `SELECT` only).
   - If `omnisql` is not configured or target is a local file (CSV/Parquet), use DuckDB via `data-scientist` patterns (`data-scientist` is a global-only skill; when absent, apply inline DuckDB guidance — aggregate in place, never load raw rows).
   - Sizing Probe: Confirm working dataset volume is under 25% free RAM before any in-memory DataFrame operations; stream or aggregate in-place.
2. **Metric Feasibility Contract (BOUNDED)**:
   - Do NOT run open-ended, unbounded exploratory analysis.
   - The candidate metric list comes from the Phase 0 register — **never from the schema**. The schema only answers "can we serve it", never "should we show it".
   - List every metric/KPI the dashboard intends to chart and verify that each metric can be served by **one feasible SQL aggregation query**.
   - Always append `LIMIT` (e.g. `LIMIT 100`) on probing queries. Verify execution feasibility via `EXPLAIN` before declaring a metric feasible.
   - Ban `SELECT *`. Enforce covering indexes, composite ordering (`equality` then `range`), and cursor pagination over offset pagination (`postgres-patterns` / `mysql-patterns`).
3. **Data Volume & Chart Type Alignment** (rendering rule, inline — no external skill dependency):
   - `< 1,000` data points: SVG rendering (Recharts / Chart.js).
   - `1,000 - 10,000` data points: HTML5 Canvas with client-side downsampling.
   - `> 10,000` data points: Backend rollup/interval aggregation (DuckDB / ClickHouse) before sending to client.
4. **Deliverable of Phase 1**:
   Produce a Bounded Metric Table (every row must cite a Phase 0 register row):

   | Register # | Metric / KPI | Underlying Tables | Aggregation Logic | Data Volume | Chart Archetype | Feasible? |
   | :--- | :--- | :--- | :--- | :--- | :--- | :--- |

---

### Phase 2: Design Direction & Tone Selection
Establish the visual foundation and aesthetic tone using the `frontend-design-direction` skill:

1. **Aesthetic Direction**:
   - Determine tone, color temperature, and information density based on audience (e.g. Operational High-Density WMS/OMS, Clean Editorial SaaS, Dark Technical Terminal).
   - Establish typography hierarchy: `font-sans tabular-nums` for all metrics and monetary figures (NEVER `font-mono`).
2. **Eliminate Overlapping Skills**:
   - **Skip `design-system`** on greenfield dashboard features. `design-system` is an extraction tool for legacy codebases; running it creates competing token sources and token drift.
   - Ground all visual tokens in Phase 3 under `design-contract-system`.
3. **Chart Library Selection (EXCLUSIVE CHOICE)**:
   - Pick **ONE** charting library based on requirements:
     - **Recharts**: Chosen when charts need full custom composability and strict binding to design contract CSS variables (`hsl(var(--primary))`).
     - **Tremor**: Chosen for rapid dashboard delivery with pre-built KPI cards and charts (bind Tremor colors to Tailwind theme tokens early to avoid theme overrides).
   - **STRICT RULE**: Do NOT import both libraries. Tremor wraps Recharts and injects competing CSS variables.
4. **Deliverable of Phase 2**:
   Record the visual direction decision (Aesthetic Name, Palette Archetype, Chart Library Choice, Density Profile).

---

### Phase 3: Design Contract Authoring with 10 UI States
Codify the specifications into a frozen design contract using the `design-contract-system` skill:

1. **Scaffold Contract File**:
   - Derive `[FEATURE]` slug from `$ARGUMENTS`: lowercase, sanitize to `[a-z0-9-]` (strip all slashes, `..`, and special characters). Reject any path traversal attempt. If the result is empty (no arguments or all-special-character input), fall back to `dashboard`.
   - Ensure destination directory exists: `mkdir -p docs/design/contracts/`
   - Target path: `docs/design/contracts/[FEATURE]-CONTRACT.md` (e.g. `docs/design/contracts/warehouse-dashboard-contract.md`).
   - Use the contract template from `skills/design-contract-system/templates/page-contract.md`.
2. **Concrete Component Mapping**:
   - Map every UI block in Section 3 to concrete shadcn UI components (`DataTable`, `Card`, `Skeleton`, `Alert`, `Toast`, `Badge`, `Button`).
   - Associate concrete Component IDs with each section.
3. **Prescribe All 10 UI States NOW (CRITICAL ARCHITECTURAL RULE)**:
   - Author Section 4 (*State Matrix Implementation for this View*) during contract creation, NOT post-hoc during audit.
   - Address each mandatory system state explicitly matching the canonical template:
     1. `1. Loading Skeleton`: Skeletons match exact card/table row height.
     2. `2. Empty State`: Custom empty illustration/icon with call-to-action.
     3. `3. No Search Result`: Search input retains query; "Clear search" button active.
     4. `4. Error State`: Inline alert with retry button; navigation remains intact.
     5. `5. No Internet`: Offline notification banner rendered.
     6. `6. Slow Network`: Optimistic updates or top loading bar after 1500ms.
     7. `7. Permission Denied`: Restricted access banner with contact admin prompt (or `[OUT_OF_SCOPE: Reason]`).
     8. `8. Session Expired`: Re-auth modal pops without discarding view inputs (or `[OUT_OF_SCOPE: Reason]`).
     9. `9. Form Validation`: Field errors positioned directly under inputs with `text-danger-fg` (or `[OUT_OF_SCOPE: Reason]`).
     10. `10. Success State`: Action confirmation toast appears with auto-dismiss.
   - Any state not applicable to this specific view MUST be explicitly marked `[OUT_OF_SCOPE: Reason]` so audit gates do not flag intentional omissions.
4. **Deliverable of Phase 3**:
   A frozen, fully specified `docs/design/contracts/[FEATURE]-CONTRACT.md`.

---

### Phase 4: Implementation Planning & Execution Handoff
Hand off the frozen design contract to the execution pipeline without redesigning:

1. **Handoff to `/plan` (`planner`)**:
   - Pass the frozen contract path to the `planner` subagent.
   - Enforce Rule: The design contract, `TOKEN-MAP.md`, and `STATES-MATRIX.md` are **read-only inputs**. `planner` maps rows to files and execution steps; it does NOT redesign UI or invent new tokens.
2. **Plan Verification via Momus (`plan-reviewer`)**:
   - Run `plan-reviewer` to verify all referenced component paths, exports, and mock utilities exist on disk.
3. **Execution via TDD (`tdd-workflow` & `frontend-patterns`)**:
   - Build data fetching hooks with error/loading state handling (`useQuery`).
   - Construct components using the 3-tier radius (`rounded-lg` 8px, `rounded-xl` 12px, `rounded-2xl` 16px) and strict 4px spacing grid (`p-1` through `p-12`).
   - Ensure WCAG 2.2 AA accessibility: hue is never the sole differentiator across chart series (use stroke patterns, direct labels, and accessible data table fallbacks).
4. **Post-Hoc Verification Gate**:
   - Run the canonical `design-contract-system` Phase 4 audit greps against `git diff --staged`:
     ```bash
     # 1. Check for forbidden hardcoded hex values in classes
     git diff --staged | grep -E "bg-\[#|text-\[#|border-\[#|fill-\[#" && echo "VIOLATION: Hardcoded hex found!" || echo "OK: no hardcoded hex"

     # 2. Check for unauthorized radius classes
     git diff --staged | grep -E "rounded-sm|rounded-md|rounded-3xl|rounded-\[" && echo "VIOLATION: Invalid radius tier!" || echo "OK: radius tiers"

     # 3. Check for fractional spacing or arbitrary non-4px units
     git diff --staged | grep -E "gap-1\.5|gap-2\.5|p-3\.5|m-\[|px-\[|pt-\[|w-\[|h-\[" && echo "VIOLATION: Non-4px spacing found!" || echo "OK: spacing grid"
     ```
   - Verify that all 10 states contracted in Section 4 are implemented in code.
