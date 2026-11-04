# STATES-MATRIX — The 10 Mandatory UI & System States

> **Zero Untreated States**: An interface is unfinished if it only handles the happy path. Every dynamic view, table, and data container must explicitly implement all 10 states below.

---

## The 10 Mandatory System States

### 1. Initial / Loading State (Skeletal Loaders)
- **Pattern**: Dimension-matched skeletons (`animate-pulse bg-surface-subdued rounded-lg`).
- **Rule**: Never use a generic centered circular spinner for entire page views. Skeleton shapes must mirror the exact dimensions of incoming cards, table rows, and metric boxes to prevent layout shift (CLS = 0).

### 2. Empty State (First-Time User)
- **Pattern**: Centered card with illustrative icon container (`rounded-xl p-3 bg-surface-subdued text-text-muted`), clear headline ("No orders yet"), brief 1-line guidance ("Create your first order to begin tracking dispatch"), and a prominent primary CTA button.
- **Rule**: Never leave an empty white box or plain "No data" text string.

### 3. No Search / Filter Result State
- **Pattern**: Different from first-time empty state. Headline: "No results matching '[query]'". Subtitle: "Check spelling or clear filters to see all records". Action: Secondary button "Clear all filters" (`variant="secondary"`).
- **Rule**: Must allow the user to recover in one click.

### 4. Error State (Network / Server Failure)
- **Pattern**: Inline error box (`bg-danger-bg/50 border border-danger-border text-danger-fg rounded-xl p-4`) with an alert icon, clear human-readable error summary (never raw stack traces or SQL codes), and a "Retry action" button.
- **Rule**: Error state must not break navigation or freeze the sidebar/topbar.

### 5. No Internet / Offline State
- **Pattern**: Sticky top banner or fixed modal overlay (`bg-warning-bg border-warning-border text-warning-fg`) indicating "Offline mode: reconnecting...". Actions requiring network must be disabled with tooltip explanation.
- **Rule**: Local cached inputs must be preserved in memory/localStorage; do not clear form state on disconnect.

### 6. Slow Network / Degraded State
- **Pattern**: Subtle top-edge progress bar or indicator ("Slow connection: fetching data...") triggered when request duration exceeds 1500ms.
- **Rule**: Provide optimistic UI updates for safe, local-first actions with graceful rollback on timeout.

### 7. Permission Denied / Unauthorized State
- **Pattern**: Shield or lock icon container (`bg-surface-subdued text-text-muted`), title: "Access Restricted", explanation: "You need role '[Required Role]' to view this module", and an action button "Request Access" or "Back to Home".
- **Rule**: Never silently redirect without explaining why access was denied.

### 8. Session Expired State
- **Pattern**: Clean modal dialog over blurred backdrop preserving current scroll position and draft data. "Session expired. Re-authenticate to continue without losing your work."
- **Rule**: Form state must be cached so re-logging in does not wipe partially filled inputs.

### 9. Form Validation State (Field & Global)
- **Pattern**:
  - Valid: standard border `border-border-subtle`.
  - Invalid: border turns `border-danger`, input background gains subtle tint, and a concise error message appears below the input (`text-xs text-danger-fg mt-1`).
  - Summary Alert: If >3 errors exist, display an alert banner above submit listing missing required fields.
- **Rule**: Validation must trigger on blur or submit; do not harass user on first keystroke.

### 10. Success State
- **Pattern**:
  - Transient actions: Top-right toast notification (`z-50`) with checkmark and confirmation message (auto-dismiss 4000ms).
  - Multi-step completion (e.g. checkout, onboarding): Dedicated success screen with receipt summary, primary action ("View Order"), and secondary action ("Back to Dashboard").
- **Rule**: Re-enable action buttons immediately; prevent duplicate double-submits with loading indicator during flight.
