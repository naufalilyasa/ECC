# Visual DNA Extraction Protocol

This document governs how to extract structured design tokens and contracts from visual references (screenshots, mockups, or HTML exports).

---

## 1. Input Modality Routing

### Mode A: Image / Screenshot Reference
When the user provides an image path or screenshot (e.g. from v0, Lovable, Stitch, Dribbble, or a live site):

1. **Dispatch the `multimodal-looker` Subagent**:
   ```
   subagent(agent="multimodal-looker", description="Extract visual DNA from screenshot")
   "Read the image at `<path-to-image>`. Extract the design DNA:
   1. Visual Hierarchy: containers, navigation, cards, tables, headers.
   2. Semantic Color Tokens: canvas backdrop, surface cards, primary buttons, text levels (strong, default, muted), borders, and status badges.
   3. Typography Scale: display headings, card titles, body, caption, and whether numbers use Sans tabular-nums or Monospace.
   4. Spacing & Geometry: card padding, grid gaps, and corner radiuses.
   5. Interactive States: buttons, badges, indicators visible.
   Format as structured markdown with estimated hex codes and functional roles."
   ```

2. **Ground Extracted Tokens**:
   - Translate extracted visual colors into semantic role names (`surface`, `text-strong`, `primary`, `border-subtle`).
   - Round pixel radiuses into the nearest of the 3 canonical tiers: `rounded-lg` (8px), `rounded-xl` (12px), or `rounded-2xl` (16px).
   - Snap spacing values to the 4px scale (`p-1` to `p-12`).

### Mode B: HTML / CSS Export Reference
When the user provides an HTML export (e.g. `mockup.html` from v0 or Stitch):

1. **Extract CSS Variables & Theme Definitions**:
   - Inspect `:root`, `@theme`, `@layer base`, or `<style>` blocks for color definitions.
   - Trace color mappings between light mode and dark mode.
2. **Audit Tailwind Classes & Inline Styles**:
   - Grep for unique background (`bg-*`), text (`text-*`), border (`border-*`), radius (`rounded-*`), and spacing (`p-*`, `gap-*`) classes.
   - Detect repeated custom patterns.
3. **Harmonize into the 33 Semantic Tokens**:
   - Map one-off values to canonical tokens.
   - Eliminate duplicated color roles.

---

## 2. Token Normalization Rules

- **No Hex Duplication**: If the same dark navy hex `#1B2A41` is used for both a primary button background and high-contrast text, separate them semantically:
  - `primary` = `#1B2A41`
  - `text-strong` = `#1B2A41` (or `#0F172A`)
  This guarantees that darkening a button does not accidentally darken all text titles across the app.
- **Light/Dark Parity**: Every surface, text, and border token must have a designated Dark Mode counterpart that maintains equivalent contrast.
