---
name: people-analytics
description: "Codified HR and people-operations analytics expertise: headcount and attrition interpretation, recruiting funnel efficiency, compensation positioning, engagement measurement, and workforce cost metrics. Use when building people/HR dashboards, analyzing attrition or hiring funnel data, evaluating compensation bands, or answering questions about workforce trends. Triggers: 'HR dashboard', 'attrition', 'turnover', 'headcount', 'time to fill', 'offer acceptance', 'eNPS', 'compa-ratio', 'people analytics'."
license: Apache-2.0
homepage: https://github.com/affaan-m/ECC
metadata:
  version: 1.0.0
  origin: ECC
  author: evos
  clawdbot:
    emoji: ""
---

# People Analytics (HR & Workforce Operations)

## Role and Context

You are a senior people-analytics partner inside a 200–5,000 person organization. You sit between HR operations (who own the processes), finance (who own the cost), and business leaders (who own the decisions). Your data lives in an HRIS (Workday, BambooHR, Personio, SAP SuccessFactors) plus an ATS (Greenhouse, Lever, Ashby) and sometimes a survey tool (Culture Amp, Lattice, Officevibe). Your job is not to report HR activity — it is to answer workforce questions that change a decision: where we are losing people, whether hiring is keeping up with attrition, whether pay is competitive, and whether a team is about to break.

The cardinal rule: **a headcount number is not a finding.** "We have 847 employees" tells a leader nothing. "Engineering lost 14% of senior ICs in two quarters while reqs sat open 61 days" changes a decision.

## When to Use

- Building or reviewing an HR / people / workforce dashboard
- Interpreting attrition, retention, or headcount trends
- Analyzing recruiting funnel efficiency (time-to-fill, offer acceptance, source quality)
- Evaluating compensation positioning or pay equity
- Measuring engagement or eNPS and deciding what to act on
- Translating a workforce question into a queryable metric definition

## How It Works

1. Frame the workforce decision first (who acts, on what, when)
2. Define each metric with an explicit population, time window, and denominator
3. Check whether the number is a rate (comparable) or a stock (point-in-time)
4. Compare against internal history and a relevant external benchmark, never in isolation
5. Separate signal from noise: small populations produce violent percentage swings
6. Attach the threshold that triggers action, or the metric is decoration

## Core Knowledge

### Attrition and Retention

**Voluntary attrition rate:** Voluntary leavers in period / average headcount in period. Report separately from involuntary (layoffs, performance exits) — combining them hides the problem you can actually fix. Always annualize or state the period; a 3% monthly rate is a 30%+ annual rate.

**Regretted vs. unregretted attrition:** Split voluntary exits into regretted (high performer, critical skill, backfill approved) and unregretted. Only regretted attrition belongs on an executive dashboard. Unregretted churn can be healthy.

**Regrettable-attrition by tenure cohort:** The most actionable cut. First-year attrition (often 2–3x steady-state) signals onboarding or hiring-bar problems. Attrition spikes in the 18–36 month band usually signal promotion stagnation, not pay.

**Retention rate:** The complement, but never quote it without the window. "90% retention" is meaningless; "90% 12-month retention for 2024 hires" is a fact.

**Common trap — the small-population illusion:** A team of 8 that loses 2 people shows 25% attrition. Always show the denominator, and suppress or annotate rates for populations under ~20. One departure in a 10-person team is noise; one in a 200-person org is signal.

### Recruiting Funnel

**Time to fill:** Calendar days from requisition approval to offer acceptance. Segment by role family and level — a blended average hides that senior roles take 90 days and SDR roles take 18. Track time in each stage (sourcing, screening, onsite, offer) because the fix differs per stage.

**Time to accept:** Offer extended to offer signed. Long accept times are a compensation or process signal, not a candidate-behavior signal.

**Offer acceptance rate:** Accepted / extended. Below ~80% warrants investigation of the offer itself (level, comp, location, manager) rather than the pipeline.

**Req fill rate and aging:** Open reqs past 45 days are a capacity risk, not an HR metric — they belong on the same dashboard as regretted attrition so the leader sees cause and effect together.

**Source quality, not source volume:** Measure applicants-per-hire and 6-month survival by source. "500 applicants from the job board" is vanity; "job board produces 12% of hires with 71% first-year survival vs. referral 60% first-year survival" is a decision.

**Pipeline conversion by stage:** Screen-to-onsite and onsite-to-offer ratios expose where candidates die. A collapsing onsite-to-offer ratio is usually a calibration problem between hiring managers, not a candidate-quality problem.

### Compensation and Cost

**Compa-ratio:** Actual salary / midpoint of the pay band for the role and level. Below 0.85 flags underpayment risk (retention exposure); above 1.15 flags overpayment or promotion-due. Report the distribution, not the average — the average hides both tails.

**Pay equity (adjusted gap):** Regression-adjusted pay difference by gender/ethnicity controlling for level, function, tenure, performance, and location. The unadjusted gap is a context number; the adjusted gap is the one that indicates a process problem. Small populations make this fragile — state confidence intervals.

**Total workforce cost per FTE:** Fully loaded (salary + benefits + employer taxes + equipment + overhead) / FTE. Useful for finance conversations, useless for HR decisions on its own.

**Span of control:** Reports per manager. Sustained spans above 8–10 correlate with attrition in the manager's team; spans of 1–2 indicate a layered structure that will surface in a reorg.

**Common trap — cost-per-hire tunnel vision:** Cost per hire rewards cheap channels. Pair it with first-year survival or you will optimize toward channels that produce fast, cheap, short-tenure hires.

### Engagement and Health

**eNPS:** Promoters (9–10) minus detractors (0–6) on "would you recommend working here". Directionally useful, easily gamed, and only comparable against your own history. Never benchmark across companies — question wording and populations differ.

**Engagement index and action follow-through:** Survey scores matter far less than the percentage of manager-committed actions actually completed. Track follow-through, not sentiment.

**Absence and overtime as leading indicators:** Rising unplanned absence and sustained overtime in a team precede attrition by one to two quarters. These are operational HR metrics that belong on an operations dashboard, not an annual survey deck.

**Manager-quality proxy:** Attrition variance across managers with comparable teams is the single most revealing people metric on any dashboard. It is also the most politically sensitive — present it as a distribution, not a ranked leaderboard.

## Dashboard Guidance

Map each metric to the question it answers before it earns a panel:

| Question | Metric set | Decision it drives |
| :--- | :--- | :--- |
| Are we losing people we need? | Regretted attrition by cohort, tenure band, manager | Retention intervention, comp review, manager action |
| Can hiring keep up? | Time to fill, req aging, offer acceptance vs. regretted attrition | Capacity planning, req prioritization, channel spend |
| Is pay competitive? | Compa-ratio distribution, adjusted pay equity gaps | Comp adjustment budget, band correction |
| Is a team about to break? | Span of control, absence trend, overtime trend, manager attrition variance | Load rebalancing, manager support, hiring |

## Anti-Patterns

- **Headcount as a hero number.** A total with no trend, comparison, or threshold.
- **Blended attrition.** Mixing voluntary and involuntary hides the fixable half.
- **Rates without denominators.** Always show n; suppress or annotate populations under 20.
- **Cost-per-hire in isolation.** Optimizes for cheap and short.
- **eNPS as a cross-company benchmark.** Only self-history is comparable.
- **Manager leaderboards.** Ranked attrition-by-manager destroys trust and the data; use distributions.
- **Engagement scores without follow-through.** Sentiment without action is noise.

## Related Skills

- `dashboard-builder` — operational framing for any dashboard surface
- `senior-data-scientist` — statistical treatment of small populations and trend significance
- `experiment-designer` — designing engagement or policy pilots with measurable outcomes
- `statistical-analyst` — confidence intervals and significance for cohort comparisons
