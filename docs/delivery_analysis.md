# Phase 15 — Delivery & Logistics Analysis

The analysis measures elapsed purchase-to-delivery hours for delivered orders
with a recorded customer delivery timestamp and a non-negative duration. State
and seller results use the same duration rule; seller metrics count distinct
seller/order pairs. Category results count distinct order/category pairs so an
order with multiple items in a category is not multiplied. These are elapsed
times, not business days.

Run and validate:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/09_delivery.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_delivery.sql
```

The analysis included **96,470** deliveries. Average delivery time was **301.40
hours (12.56 days)** and the median was **245.22 hours (10.22 days)**. There
were **7,826 late deliveries (8.11%)**. A long right tail pulls the average
above the median.

Delivery duration varied substantially by destination. Roraima (RR) had the
longest average at **705.30 hours**, but only 41 deliveries, so it should not
be treated as a stable state-level estimate. São Paulo (SP), with 40,494
deliveries, averaged **210.27 hours** and had a **5.89%** late rate. Alagoas
(AL) had the highest state late rate at **23.93%** across 397 orders. Seller
and category rankings are also descriptive; the seller table requires at least
20 orders, and lower-volume groups are especially variable.

For orders with reviews, on-time deliveries averaged **4.294** across 88,163
reviewed orders, compared with **2.566** across 7,661 late reviewed orders.
This is a strong association between lateness and lower satisfaction, not
evidence that lateness alone caused the score difference. The query averages
review rows; an order with multiple reviews contributes multiple observations,
which is why review-row counts differ from distinct reviewed-order counts.
Missing or invalid delivery dates are excluded from duration calculations and
are already examined in the data-quality phase.

`tests/test_delivery.sql` passed. It verifies the eligible population is
non-empty and bounded by delivered orders, and that reviewed eligible orders
have an on-time/late classification.
