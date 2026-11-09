# Phase 17 — Advanced SQL

The dedicated advanced-query examples are in
[sql/06_advanced_analytics/01_advanced_sql.sql](../sql/06_advanced_analytics/01_advanced_sql.sql).
They demonstrate CTEs, scalar and correlated subqueries, conditional
aggregation with `FILTER`, ordered-set percentiles, `ROW_NUMBER`, `LAG`,
`LEAD`, `FIRST_VALUE`, `LAST_VALUE`, running totals, rolling averages,
Pareto analysis, and top-N-per-group.

Run and validate:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/06_advanced_analytics/01_advanced_sql.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_advanced_sql.sql
```

The delivered merchandise order-value distribution contains **96,478
delivered orders**. Its mean is **R$137.04**, median **R$86.58**, 90th
percentile **R$269.00**, and 95th percentile **R$399.00**. The windowed
monthly revenue sequence ends at **R$13,221,498.11**, matching delivered
merchandise sales. The Pareto query finds that **8,352 products** are needed
to reach 80% of delivered sales. The top-three-per-state query uses a stable
seller-ID tie-break to return no more than three sellers in any state.

A recursive CTE is intentionally not included: the dataset has no natural
hierarchy, and a generated month calendar is clearer and more appropriate
than recursion for the time-series example.

`tests/test_advanced_sql.sql` passed. It reconciles product and monthly
running-total revenue to delivered sales, validates the Pareto cumulative
share, and checks the top-N bound.
