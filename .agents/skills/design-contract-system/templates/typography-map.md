# TYPOGRAPHY-MAP — Typography & Micro-Typography Architecture

> **Absolute Boundary**: Do not mix font roles or fall back to unmanaged system fonts.

---

## 1. Font Family Allocation

| Font Family | CSS Variable / Class | Primary Role | Absolute Restrictions |
|---|---|---|---|
| **Sans Family** (e.g. `Instrument Sans` / `Geist`) | `--font-sans` / `font-sans` | **UI & Business Metrics**: Page headings, card titles, navigation, controls, forms, and **ALL calculated numbers, prices, and percentages** (must pair with `tabular-nums`). | Do NOT use for machine identifiers or SKU codes. |
| **Mono Family** (e.g. `JetBrains Mono` / `Geist Mono`) | `--font-mono` / `font-mono` | **Code & Machine Identifiers**: SKU codes (`#SKU-9021`), order IDs, tracking numbers, warehouse locations, API keys, and keyboard shortcuts (`⌘K`). | Do NOT use for large KPI totals or chart axes. |
| **Brand Family** (Optional Display) | `--font-display` / `font-display` | **Brand Wordmark Only**: High-personality logo title in topbar or sidebar. | Prohibited on standard UI cards and tables. |

---

## 2. The Golden Rule of Numbers: Sans vs Mono

1. **Use `font-sans tabular-nums`** if the number is a **countable, calculable metric or amount** (e.g. `1,643 orders`, `Rp 124.839.000`, `94.2%`, `$4,250.00`).
   - *Why*: Keeps metric cards and financial figures clean, modern, and aligned without rigid typewriter monospace aesthetics.
2. **Use `font-mono tabular-nums`** if the text is a **unique identifier or barcode address** where characters must be read precisely without confusing `O` with `0` or `I` with `1` (e.g. `#SKU-83009`, `TRACK-882910`, `BIN-04-B2`).

---

## 3. Typographic Hierarchy Scale

| Level | Size | Weight | Line Height | Tracking | Typical Class Combination |
|---|---|---|---|---|---|
| **Display / H1** | 28px–32px | Bold (700) | 1.2 | `-0.02em` | `text-2xl md:text-3xl font-bold tracking-tight text-text-strong` |
| **Section / H2** | 20px–24px | Semi-bold (600) | 1.25 | `-0.015em` | `text-xl md:text-2xl font-semibold tracking-tight text-text-strong` |
| **Card Header / H3** | 16px–18px | Semi-bold (600) | 1.3 | `-0.01em` | `text-base md:text-lg font-semibold text-text-strong` |
| **Body (Default)** | 14px–15px | Regular (400) | 1.5 | `normal` | `text-sm md:text-base font-normal text-text-default leading-relaxed` |
| **Caption / Meta** | 12px–13px | Medium (500) | 1.4 | `0.01em` | `text-xs font-medium text-text-muted` |
| **Badge / Small Tag**| 11px–12px | Semi-bold (600) | 1 | `0.02em` | `text-[11px] font-semibold uppercase tracking-wider` |
