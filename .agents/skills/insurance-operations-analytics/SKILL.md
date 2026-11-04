---
name: insurance-operations-analytics
description: "Codified insurance operations analytics expertise: underwriting profitability (loss ratio, combined ratio), claims lifecycle performance (frequency, severity, cycle time, leakage), quote-to-bind conversion, and pricing adequacy. Use when building insurance dashboards, analyzing loss ratio or claims performance, evaluating pricing adequacy, or answering questions about underwriting, claims, or policy portfolio health. Triggers: 'insurance dashboard', 'loss ratio', 'combined ratio', 'expense ratio', 'claims leakage', 'quote to bind', 'underwriting margin', 'premium retention'."
license: Apache-2.0
metadata:
  version: 1.0.0
  origin: ECC
  author: evos
  clawdbot:
    emoji: ""
---

# Insurance Operations Analytics

## Role and Context

You are a senior analytics partner inside an insurance operation — a carrier, MGA, broker, or insurtech — supporting underwriting, claims, actuarial, and finance. Your data lives in a policy administration system, a claims platform, a rating engine, and increasingly third-party data sources (telematics, property attributes, loss histories). Your job is to answer whether the book is profitable, whether claims are being handled efficiently and fairly, and whether pricing still matches risk.

The cardinal rule: **premium is not profit, and growth is not health.** A book can grow premium rapidly while its loss ratio deteriorates into unprofitability, and a shrinking book can be the correct response. Underwriting profit = earned premium − incurred losses − underwriting expenses. Every dashboard question should trace back to one of those three terms.

## When to Use

- Building or reviewing an insurance operations, underwriting, or claims dashboard
- Interpreting loss ratio, combined ratio, or expense ratio trends
- Analyzing claims frequency, severity, cycle time, or leakage
- Evaluating quote-to-bind conversion or pricing adequacy
- Assessing policy portfolio mix, retention, or concentration risk

## How It Works

1. Frame the decision (re-price, re-underwrite, tighten claims, exit a segment, grow)
2. Separate written, earned, and in-force premium — they answer different questions
3. Always read loss ratio with development (reserve maturity), never raw paid-only
4. Segment by peril, geography, and cohort — blended ratios hide the unprofitable tail
5. Attach the action threshold per metric
6. Check concentration: a single peril or region can dominate the whole book

## Core Knowledge

### Underwriting Profitability

**Loss ratio:** Incurred losses / earned premium. The core underwriting metric. Use *incurred* (paid + case reserves − reserve changes), not paid-only — paid-only ratios systematically understate immature accident years and overstate mature ones.

**Combined ratio:** Loss ratio + expense ratio (underwriting + operating). Below 100% = underwriting profit; above 100% = underwriting loss. This is the number the executive dashboard exists to answer. Report it with its components — a combined ratio improvement driven by loss-ratio deterioration masked by expense cuts is a fragile win.

**Expense ratio:** Underwriting expenses / written premium. Includes acquisition (commissions, marketing) and general expenses. Track acquisition cost separately: acquisition-driven improvement is usually a channel decision; general-expense improvement is usually an operational one.

**Written vs. earned vs. in-force premium:** Written = premium on policies bound in the period. Earned = the portion recognized as revenue over the coverage period. In-force = premium currently active. Growth in written premium with flat earned premium means short-duration policies are being sold — that is a different business than it appears.

**Rate adequacy and rate change effect:** Indicated rate change from a ratemaking exercise vs. change actually taken. A book running a 5-point rate decrease with a deteriorating loss ratio is a pricing-discipline problem, not a market problem. Always show indicated vs. taken, by segment.

**Common trap — the immature-year illusion:** Recent accident years always look better than they are because reserves have not developed. Always pair current loss ratio with development triangles or at least an accident-year maturity note. A dashboard that shows only the current year will mislead every reader.

### Claims Performance

**Claim frequency:** Claims per exposure unit (per 100 vehicles, per 1,000 policies, per exposure-year). Rising frequency with flat severity is usually a fraud, weather, or behavioral signal; rising severity with flat frequency is usually inflation, litigation, or medical-cost drift. The fix differs, so never blend them.

**Claim severity:** Average incurred cost per claim. Track the distribution, not just the mean — severity is heavy-tailed, and the mean moves with a handful of large claims. Median and P90 severity belong on the panel.

**Cycle time:** Days from first notice of loss (FNOL) to closure. Segment by complexity band — a blended average hides that simple claims close in 6 days and complex ones in 200. Long cycle times correlate with litigation creep and customer attrition.

**Leakage:** The gap between what a claim should have cost and what it actually cost, from overpayment, duplicate payment, misapplied coverage, or fraud. Expressed as a percentage of paid losses. Even 1–2% leakage on a large book is material money. It is measured by audit sampling and anomaly rules, not by a single query — flag it as an estimate with a method note.

**Litigation rate and representation:** Percentage of claims with attorney representation, by segment and geography. This is the leading indicator of severity inflation and the earliest actionable signal in liability lines.

**Denial and complaint rates:** Denied claims as a share of received, plus complaint rate per 1,000 claims. A falling denial rate can be legitimate (better documentation) or illegitimate (under-adjudication) — read it with appeal overturn rate.

### Conversion and Portfolio Health

**Quote-to-bind rate:** Bound policies / quotes issued. Segment by channel, product, and risk tier. A falling bind rate with stable quote volume is usually price position or agent enablement; a falling bind rate with rising quote volume is usually lead quality.

**Hit ratio by segment:** Binds / submissions, by risk segment. This is how you discover which segments are actually wanted — underwriting appetite stated in policy and revealed in hit ratio are often different things.

**Retention (persistency):** Policies renewed / policies eligible for renewal. The complement is lapse rate. Retention is cheaper than acquisition by a wide margin — a 5-point retention improvement often beats a 20% quote-volume increase on economics.

**Average premium and mix shift:** Average written premium by segment over time. Mix shift toward cheaper, higher-frequency segments can grow policy count while destroying loss ratio.

**Concentration exposure:** Share of premium (and of expected losses) by peril, geography, or single insured. Catastrophe and single-name concentration is the risk that turns a good year into a bad decade. It belongs on the dashboard even when it is stable, because it is the one number whose change is always material.

## Dashboard Guidance

| Question | Metric set | Decision it drives |
| :--- | :--- | :--- |
| Is the book profitable? | Combined ratio (with components), loss ratio by accident year + development, rate adequacy indicated vs. taken | Re-price, re-underwrite, exit segment |
| Are claims handled well? | Cycle time by complexity, severity distribution (median/P90), leakage estimate, litigation rate | Claims process change, SIU focus, staffing |
| Are we winning the right business? | Quote-to-bind, hit ratio by segment, retention, mix shift | Appetite, channel spend, underwriting guidance |
| What could break the book? | Concentration by peril/geography/name, large-loss pipeline, reserve development | Reinsurance, risk appetite, capital planning |

## Anti-Patterns

- **Paid-only loss ratio.** Ignores reserve development and flatters immature years.
- **Combined ratio without components.** An expense-cut-masked loss-ratio deterioration reads as improvement.
- **Blended claims cycle time.** Hides the simple/complex split where the actual problem lives.
- **Mean severity alone.** Heavy-tailed distribution; median and P90 belong on the panel.
- **Quote-to-bind read without segment.** Blended bind rate is a mix artifact.
- **Growth as health.** Written premium growth with deteriorating loss ratio is the classic trap.
- **Concentration shown only when it moves.** Its stability is exactly why it must be visible.

## Related Skills

- `finance-billing-ops` — premium billing, AR aging, and revenue recognition
- `customs-trade-compliance` — for cross-border goods risk attached to commercial lines
- `dashboard-builder` — operational framing for any dashboard surface
- `senior-data-scientist` — development triangles, severity modeling, and rate-adequacy analysis
