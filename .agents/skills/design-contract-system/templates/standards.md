# STANDARDS — UI Engineering & Geometry Rulebook

> **Binding Contract**: Every frontend component must follow these exact rules. Personal aesthetic preferences are superseded by this specification.

---

## 1. Corner Radius — Exactly 3 Tiers

No arbitrary radiuses. `rounded-md`, `rounded-sm`, `rounded-3xl` are prohibited on standard components.

| Class | Value | Allowed Components |
|---|---|---|
| `rounded-lg` | 8px | Interactive controls: `Button`, `Input`, `Select`, `Textarea`, icon boxes, alert banners |
| `rounded-xl` | 12px | Containers & panels: `Card`, `StatCard`, `SectionCard`, nested wells, table containers, popover menus |
| `rounded-2xl` | 16px | Large overlays: `Modal`, dialog windows, sheet drawers (`rounded-l-2xl`) |

*Capsule Exception*: `rounded-full` is exclusively reserved for status badges, trend delta pills, progress bars, avatar chips, and status indicator dots.

---

## 2. Spacing Scale — Multiples of 4px

All padding, margin, and gap values must strictly follow the 4px scale.

| Multiplier | Class | Pixel Value | Typical Application |
|---|---|---|---|
| `1` | `p-1` / `gap-1` | 4px | Micro-spacing between icon and small label |
| `2` | `p-2` / `gap-2` | 8px | Button inner padding (small), list item gap |
| `3` | `p-3` / `gap-3` | 12px | Input inner padding, form field vertical gap |
| `4` | `p-4` / `gap-4` | 16px | Standard card padding, Bento grid card gaps |
| `5` | `p-5` / `gap-5` | 20px | Medium card padding (`StatCard`), table header padding |
| `6` | `p-6` / `gap-6` | 24px | Large section card padding, separation between sections |
| `8` | `p-8` / `gap-8` | 32px | Page-level outer container padding |
| `12` | `p-12` / `gap-12`| 48px | Major layout division margin |

Arbitrary values (`p-[13px]`, `gap-2.5`) are banned. Round to nearest scale step.

---

## 3. Touch Targets & Interaction Dimensions

- **Desktop Minimum**: 36px height (`h-9`) for compact data controls; 40px (`h-10`) for standard buttons/inputs.
- **Mobile Minimum**: 44px height (`h-11`) minimum hit area for all touch surfaces.
- **Hover & Focus Transitions**: `transition-colors duration-150 ease-out`. Focus ring: `focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none`.

---

## 4. Z-Index Ladder

Do not invent random z-index values (e.g. `z-[9999]`). Use the designated ladder:

| Level | Class | Used For |
|---|---|---|
| `1` | `z-10` | Sticky table headers, subtle card accents |
| `2` | `z-20` | Sticky top navigation bar |
| `3` | `z-30` | Sidebar navigation, drawer overlays |
| `4` | `z-40` | Floating dropdown menus, popovers, tooltips |
| `5` | `z-50` | Modals, full-screen dialogs, global toast notifications |

---

## 5. Feedback Post-Action: Toast vs Alert

- **Toast (`z-50`)**: For transient, asynchronous feedback ("Order saved", "Export queued"). Must auto-dismiss in 4000ms.
- **Alert Banner (inline)**: For persistent state blocks ("Database sync degraded", "Subscription payment past due"). Stays visible until resolved.
