# Phase 13 — Product Analysis

The analysis uses delivered item prices and reports product review averages from
orders containing the product. A review is associated once per product/order/
review combination; multiple reviews on an order remain separate observations.
Products without sales are retained in the product-level ranking, and
untranslated categories use source category names or `[Uncategorized]`.

Run from the repository root:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/07_products.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_products.sql
```

Health and beauty led category sales at **R$ 1,233,131.72**, followed by
watches and gifts (**R$ 1,166,176.98**) and bed/bath/table (**R$ 1,023,434.76**).
The top product was `bb50f2e236e5eea0100680137654686c`, with R$ 63,560 across
194 delivered item rows and a 4.21 average review score from 188 reviews.

The product Pareto calculation found **8,352 of 32,951 products (25.93%)** are
needed to reach at least 80% of delivered merchandise sales. Sales quartiles
are rank bins with product ID as a deterministic tie breaker, not a causal
performance grouping. The product-rating analysis surfaces low-rating/high-
sales combinations for investigation; ratings do not explain why sales occur.

`tests/test_products.sql` passed and confirms product and category rollups
reconcile to total delivered item sales. Product averages use available review
records; selection and non-response effects may bias the average rating.
