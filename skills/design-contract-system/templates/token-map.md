# TOKEN-MAP — Developer's Semantic Token Quick Reference

> **The Golden Rule**: Choose tokens based on their **role**, NEVER by the color you happen to want. Never hardcode arbitrary hex codes into Tailwind class names.

---

## 1. Role-Based Token Mapping

| UI Element Role | Tailwind Utility Class | CSS Variable | Forbidden Anti-Pattern |
|---|---|---|---|
| **Page Backdrop** | `bg-canvas` | `var(--color-canvas)` | `bg-gray-100`, `bg-[#F8FAFC]` |
| **Main Card Container** | `bg-surface border-border-subtle` | `var(--color-surface)` | `bg-white`, `border-gray-200` |
| **Nested Sub-Panel** | `bg-surface-subdued` | `var(--color-surface-subdued)` | `bg-gray-50`, `bg-zinc-100` |
| **Primary Action Button** | `bg-primary text-primary-fg hover:bg-primary-hover` | `var(--color-primary)` | `bg-black`, `bg-blue-600` |
| **Page & Section Title** | `text-text-strong` | `var(--color-text-strong)` | `text-black`, `text-slate-900` |
| **Standard Paragraph** | `text-text-default` | `var(--color-text-default)` | `text-gray-700`, `text-gray-800` |
| **Supporting Subtitle** | `text-text-muted` | `var(--color-text-muted)` | `text-gray-500` |
| **Input / Form Border** | `border-border-strong` | `var(--color-border-strong)` | `border-gray-400` |
| **Focus Indicator** | `ring-accent` | `var(--color-accent)` | `ring-purple-500` |
| **Success Status Pill** | `bg-success-bg text-success-fg` | `var(--color-success-*)` | `bg-green-100 text-green-800` |
| **Warning Status Pill** | `bg-warning-bg text-warning-fg` | `var(--color-warning-*)` | `bg-yellow-100 text-yellow-800` |
| **Danger Status Pill** | `bg-danger-bg text-danger-fg` | `var(--color-danger-*)` | `bg-red-100 text-red-800` |

---

## 2. Token Extension Protocol

If a genuinely new UI role emerges that cannot be satisfied by existing tokens:
1. Do NOT write one-off inline hex codes (`bg-[#123456]`).
2. Propose the new role name in `docs/design/TOKEN-MAP.md` explaining why existing tokens fail.
3. Add the token pairing (Light and Dark) into `apps/web/src/app/globals.css`.
4. Only then consume the new semantic class in UI components.
