# Phase 12 — Customer Lifetime Value

## Definition and assumptions

Historical revenue and order metrics include delivered merchandise item prices
only; freight and costs/margins are unavailable. Historical customer value is
the sum of delivered merchandise sales and is not profit.

The estimated value is a **12-month annualized spending proxy**, not a
prediction of true lifetime value. For a repeat buyer, observed order frequency
is annualized from the days between their first and last delivered orders;
average order value multiplied by this annualized frequency estimates a
12-month run rate. The estimate is produced only when the observed lifespan is
at least 30 days. Shorter windows annualize to unstable values, and one-time
customers have no observed repeat frequency, so the proxy is NULL for them.
This assumes historical repeat behavior continues and is particularly
uncertain when based on only two orders.

Run the query and assertions:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/06_customer_lifetime_value.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_clv.sql
```

## Current results

| Delivered-order history | Customers | Average historical revenue | Average order value | Mean observed lifespan | Mean annualized frequency | Mean 12-month proxy |
|---|---:|---:|---:|---:|---:|---:|
| No delivered order | 2,738 | R$ 0.00 | — | — | — | — |
| One delivered order | 90,557 | R$ 137.96 | R$ 137.96 | — | — | — |
| Repeat delivered buyer | 2,801 | R$ 260.05 | R$ 122.96 | 88.2 days | 8.03 orders/year* | R$ 957.70* |

*Annualized values are averaged only over repeat buyers with at least 30 days
between first and last delivered purchases; their short observation periods
still make extrapolations uncertain. The customer-level query provides the
highest proxy examples for inspection.

## Validation and limitation

`tests/test_clv.sql` passed. It reconciles customer historical sales to
delivered item sales and checks proxy eligibility. This proxy should not be
used for budgeting or customer acquisition decisions without a longer follow-up
window, gross-margin data, and a validated retention/churn model.
