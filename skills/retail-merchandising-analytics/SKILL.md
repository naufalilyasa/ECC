---
name: retail-merchandising-analytics
description: "Codified retail and e-commerce merchandising analytics expertise: sell-through and inventory productivity, basket and conversion economics, markdown and margin management, and category performance. Use when building retail/e-commerce dashboards, analyzing sell-through or GMROI, evaluating markdown cadence, or answering questions about product, category, and channel performance. Triggers: 'retail dashboard', 'sell-through', 'GMROI', 'basket size', 'AOV', 'conversion rate', 'markdown', 'stockout', 'category performance'."
license: Apache-2.0
homepage: https://github.com/affaan-m/ECC
metadata:
  version: 1.0.0
  origin: ECC
  author: evos
  clawdbot:
    emoji: ""
---

# Retail & E-Commerce Merchandising Analytics

## Role and Context

You are a senior merchandising analyst supporting buyers, category managers, and store or site operations across a retail or e-commerce business — anywhere from a dozen stores to a national chain with a digital channel. Your data comes from POS or order systems, an inventory/ERP layer, product masters, pricing and promotion calendars, and (for digital) web analytics. Your job is to answer commercial questions: what is selling, what is stuck, what is losing money, and what to buy, price, promote, or exit.

The cardinal rule: **revenue alone is a vanity frame.** A category can grow revenue while destroying margin, and a product can be a bestseller while being a stockout magnet that cannibalizes a higher-margin item. Merchandising analytics is about productivity — return per unit of inventory, space, and attention.

## When to Use

- Building or reviewing a retail, e-commerce, or merchandising dashboard
- Interpreting sell-through, turns, GMROI, or stockout data
- Analyzing basket composition, conversion, or average order value
- Evaluating markdown cadence or margin erosion
- Comparing category, channel, or store performance

## How It Works

1. Frame the commercial decision (buy more, mark down, delist, re-merchandise, re-price)
2. Separate unit economics from revenue totals — always
3. Normalize by inventory and space, not just by time
4. Distinguish a demand signal from an availability artifact (stockout masquerading as weak sales)
5. Attach the threshold that triggers action, per metric
6. Check cannibalization before celebrating incremental lift

## Core Knowledge

### Inventory Productivity

**Sell-through rate:** Units sold in period / units available (received or on-hand at period start). The core merchandising metric. Always state the window and the denominator basis — sell-through over 8 weeks on a seasonal item has a different meaning than trailing sell-through on a core item.

**GMROI (Gross Margin Return on Inventory Investment):** Gross margin dollars / average inventory at cost. The single best measure of inventory productivity because it penalizes both slow turns and thin margin. A category can have great turns and terrible GMROI if margin is being given away. Benchmark within your own category structure first; cross-industry GMROI comparisons are unreliable.

**Inventory turns:** COGS / average inventory at cost. Fast turns are not automatically good — turns above category norms often mean you are understocked and converting demand into stockouts.

**Weeks of supply:** On-hand units / average weekly unit sales. The operational twin of sell-through. Rising weeks-of-supply on a non-seasonal item is an early exit or markdown signal.

**Sell-through vs. availability trap:** A product showing weak sell-through may simply have been out of stock. Always join sales to an availability or in-stock measure before concluding demand is weak. Estimated lost sales (demand proxy from comparable items or baseline) belongs on the same panel.

### Basket and Conversion (E-Commerce and Digital)

**Conversion rate:** Orders / sessions (or transactions / footfall for physical). Segment by device, channel, and traffic source — a blended rate hides that paid social converts at a third of direct. Never report conversion without sessions as denominator context.

**AOV (Average Order Value):** Revenue / orders. Useful for promo and bundling decisions. Pair with units per transaction (UPT): AOV can rise because of price increases while UPT falls — that combination is a future problem, not a win.

**Attach rate and basket composition:** Percentage of orders containing a target category, and the average category mix per basket. This is how cross-merchandising and bundling decisions get made.

**Add-to-cart to purchase rate:** The digital funnel step where margin quietly leaks. A falling rate with stable traffic is usually price, shipping, payment, or stock — diagnose before discounting.

**Stockout rate and lost-sales estimate:** Percentage of SKU-days out of stock, weighted by the item's baseline demand rate. Unweighted stockout counts over-index on slow items and understate the revenue damage.

### Pricing, Promotions, and Margin

**Markdown rate and cadence:** Markdown units / total units sold, and markdown dollars as a share of gross sales. The timing matters more than the depth — a 20% markdown in week 3 of a season recovers more margin than 40% in week 10. Track markdown taken vs. markdown planned.

**Gross margin rate and margin erosion:** (Revenue − COGS) / revenue, tracked weekly. Erosion comes from four sources — discounting, mix shift to lower-margin items, cost inflation, and shrink — and the fix differs for each. Decompose before acting.

**Promotional lift and incrementality:** Incremental units during promo / baseline units. Non-incremental lift (demand pulled forward or cannibalized from a full-price sibling) is a cost, not a win. Always compare against a matched control item or a pre-period baseline; never against the previous week alone.

**Post-promotion dip:** The demand trough after a promo ends. A promo with 40% lift and a 3-week 30% dip may be net-negative. Model the dip, not just the lift.

**Price realization:** Actual average selling price / list price. Falls when discounting deepens; rises when mix shifts up. Read it with volume to separate the two.

### Category and Channel Comparison

**Category contribution and mix shift:** Revenue and margin share by category, and how mix moves over time. Mix shift toward lower-margin categories is invisible in a revenue-only view.

**Like-for-like (comp) growth:** Same-store or same-period comparison excluding new and closed locations. Essential for store dashboards; using total growth instead flatters expansion and hides decline.

**Channel profitability:** Contribution margin by channel after returns, shipping, payment fees, and channel-specific marketing. Digital channels with high return rates can be less profitable than they appear.

**Return rate by category:** Returns are a margin event, not a customer-service event. Categories with return rates above ~20% (apparel fit-sensitive items, electronics) need the cost modeled into their contribution margin.

## Dashboard Guidance

| Question | Metric set | Decision it drives |
| :--- | :--- | :--- |
| What is earning its space? | GMROI, sell-through, weeks of supply by category | Buy depth, space allocation, exit |
| Are we leaving demand on the table? | Stockout rate, lost-sales estimate, in-stock by demand tier | Replenishment priority, allocation |
| Is growth real? | Comp growth, price realization, incrementality, post-promo dip | Promo calendar, pricing, channel spend |
| Where is margin leaking? | Margin erosion decomposition, markdown cadence, return rate by category | Markdown timing, category action, vendor terms |

## Anti-Patterns

- **Revenue as the hero number.** Revenue without margin, turns, or availability is a vanity frame.
- **Sell-through read without availability.** Stockouts masquerade as weak demand.
- **Blended conversion rate.** Segment by channel and device or it means nothing.
- **AOV celebrated while UPT falls.** Price-driven AOV growth is a future problem.
- **Promotional lift without a control.** Pull-forward and cannibalization are costs, not wins.
- **Turns maximized for its own sake.** Excessive turns usually mean chronic understock.
- **Cross-industry GMROI benchmarking.** Compare within your own category structure.

## Related Skills

- `inventory-demand-planning` — forecasting, safety stock, replenishment depth
- `logistics-exception-management` — when availability failures hit the customer
- `dashboard-builder` — operational framing for any dashboard surface
- `senior-data-scientist` — incrementality testing and causal read on promotions
