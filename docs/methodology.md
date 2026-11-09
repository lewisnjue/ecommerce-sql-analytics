# Analytical Methodology

This document records the shared definitions used across the SQL analyses,
views, KPI layer, and dashboard. Phase-specific query details and result
tables are linked at the end.

## Dataset window and grains

- The source is the Olist Brazilian E-Commerce dataset. Order purchase dates
  run from 2016-09-04 through 2018-10-17 in the loaded snapshot; October 2018
  is incomplete.
- `customer_id` identifies an order-specific customer record.
  `customer_unique_id` is the person-level key for repeat-purchase, RFM, and
  cohort work.
- Order items use (`order_id`, `order_item_id`) as their grain. Reviews use
  (`review_id`, `order_id`); review IDs can repeat across orders.
- State-based customer results use the customer's recorded state. Seller
  results use the seller's recorded state. Geolocation is not resolved to a
  unique point because ZIP-prefix records repeat.

## Sales and order value

**Delivered merchandise sales** are the sum of `staging.order_items.price_brl`
for items in orders whose status is `delivered`. Freight is excluded and
reported separately as `freight_brl`. The measure is not accounting revenue,
payment volume, or profit; refunds, taxes, discounts, and costs are not fully
modeled.

Delivered order value is calculated by aggregating item prices (and, where
explicitly stated, freight) to one row per order before averaging or joining
to other entities. `order_payments` is one-to-many with orders and is not
joined directly into item-revenue sums, avoiding payment-join fan-out.

## Customer and retention metrics

- Phase 9 frequency and interpurchase intervals use all order records;
  spending remains delivered-merchandise-only. KPI repeat rate is narrower:
  customers with more than one delivered order divided by customers with at
  least one delivered order.
- RFM values use delivered orders only. The reference date is one day after
  the last purchase date in the dataset, not the current system date. Scores
  run from 1 to 5; equal metric values are scored together, so bins need not
  have equal customer counts.
- Cohorts are grouped by first delivered-purchase month and `customer_unique_id`.
  Month-one retention pools customers from cohorts whose first follow-up month
  is observable and includes zero-return cohorts in the denominator.
- The customer lifetime-value analysis reports historical merchandise spend
  and a conditional 12-month annualized spending proxy for repeat buyers
  observed for at least 30 days. It is not true lifetime value, margin, or a
  validated prediction.

## Product, seller, delivery, and reviews

- Product/category and seller sales use delivered item prices. Category names
  prefer the English translation and fall back to the source name or
  `[Uncategorized]`.
- Seller quartiles are deterministic revenue ranks among sellers, not measures
  of profitability or quality. Seller/order delivery results use distinct
  seller/order pairs to prevent multiple items from multiplying an order.
- Delivery duration is elapsed hours from purchase to customer delivery, not
  business days. Duration summaries exclude missing and negative durations.
  Late rate uses only rows with a valid duration and known on-time/late status.
- Review-score averages are review-row measures unless a query explicitly
  reports distinct orders. Category/product/seller associations are deduplicated
  at the entity/order/review grain to avoid item-row multiplication.
- Correlations between delivery and review scores are descriptive. They do not
  establish that delivery alone caused a score change.

## Data-quality handling

Raw rows are investigated before transformation. The staging refresh preserves
suspicious dates, values, missing fields, and repeated geolocation records;
flags make anomalies queryable. Blank review comments are trimmed and stored
as NULL in staging. No source anomaly is silently dropped to force a zero-count
test result.

## Reproducible definitions

The principal references are:

- [Revenue analysis](revenue_analysis.md)
- [Customer analysis](customer_analysis.md) and
  [customer segmentation](customer_segmentation.md)
- [Cohort analysis](cohort_analysis.md) and
  [customer-spend proxy](customer_lifetime_value.md)
- [Product analysis](product_analysis.md) and
  [seller analysis](seller_analysis.md)
- [Delivery analysis](delivery_analysis.md) and
  [customer satisfaction](customer_satisfaction.md)
- [KPI definitions](kpi_layer.md) and
  [SQL testing](sql_testing.md)
