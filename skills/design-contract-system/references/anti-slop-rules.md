# Anti-Slop Design & Engineering Rules

These rules eliminate generic, amateurish AI-generated design patterns ("AI slop") and ensure production-grade frontend craft.

---

## 1. Strictly Banned AI Slop Patterns

1. **The Purple/Blue Neon Glow Trap**:
   - *Banned*: Neon cyan-to-purple gradients, outer button glows (`box-shadow: 0 0 20px #8b5cf6`), illuminated card borders.
   - *Approved*: Calm, high-contrast neutral surfaces (Slate/Zinc/Off-white/Dark navy) with a single controlled accent.
2. **Arbitrary Floating Corner Radiuses**:
   - *Banned*: `rounded-3xl` on buttons, `rounded-md` on cards, mixed arbitrary radiuses (`rounded-[14px]`).
   - *Approved*: Exactly 3 tiers: `rounded-lg` (8px controls), `rounded-xl` (12px cards/containers), `rounded-2xl` (16px modals/drawers).
3. **Gratuitous Glassmorphism**:
   - *Banned*: Blurry semi-transparent cards (`backdrop-blur-md bg-white/10`) on utility enterprise software.
   - *Approved*: Solid, high-legibility surfaces (`bg-surface`) with crisp 1px borders (`border-border-subtle`).
4. **Fractional & Odd Spacings**:
   - *Banned*: `gap-1.5`, `p-3.5`, `m-[7px]`, `gap-[11px]`.
   - *Approved*: Multiples of 4px exclusively (`p-1` to `p-12`).
5. **Generic Circular Spinners for Whole Views**:
   - *Banned*: Centered spinning circle while an entire dashboard loads.
   - *Approved*: Dimension-matched layout skeletons that preserve layout geometry and prevent Cumulative Layout Shift (CLS = 0).
6. **Card-Inside-Card-Inside-Card Inception**:
   - *Banned*: Nesting 4 layers of elevated cards with heavy shadows.
   - *Approved*: Sub-panels use flat subdued surfaces (`bg-surface-subdued`) or 1px dividers, not stacked shadows.
7. **Typewriter Monospace for Business Numbers**:
   - *Banned*: Using generic monospace for sales totals or financial KPI numbers.
   - *Approved*: Sans font with OpenType `tabular-nums` for all calculable metrics; Monospace exclusively for technical codes, serials, and SKUs.
