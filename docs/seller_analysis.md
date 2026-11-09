# Phase 14 — Seller Analysis

Seller metrics attribute each order item to its recorded seller. Cancellation
rate is canceled orders divided by all orders containing that seller's items;
an order with multiple sellers is counted for each seller. Delivery hours
average non-negative purchase-to-customer-delivery durations. Review scores are
associated to a seller once per review/order pair, avoiding multiplication by
multiple seller items in the same order.

Seller tiers are relative revenue quartiles among all 3,095 sellers. Revenue is
delivered merchandise item price. Sellers are sorted by revenue and seller ID
before `NTILE(4)`, so equal revenue at a quartile boundary is deterministically
broken by seller ID. Tiers therefore describe relative sales, not overall
quality.

Run and validate:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/08_sellers.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_sellers.sql
```

The top seller is `4869f7a5dfa277a7dca6462dcf3b52b2` with **R$ 226,987.93**
delivered merchandise sales, 1,124 delivered orders, and a 4.13 average review
score. Seller review and delivery metrics are descriptive and may have
different coverage by seller.

| Relative revenue tier | Sellers | Delivered revenue |
|---|---:|---:|
| Top performers | 774 | R$ 11,577,042.99 |
| Strong performers | 774 | R$ 1,258,217.47 |
| Average performers | 774 | R$ 327,047.66 |
| Underperformers | 773 | R$ 59,189.99 |

`tests/test_sellers.sql` passed and verifies seller revenue reconciles exactly
to delivered item sales and all sellers receive a tier. The quartiles are not
profitability estimates and do not account for seller tenure, assortment,
volume, or costs.
