# Phase 11 — Cohort Analysis

## Definition and reproducibility

Customers are grouped by their first month with a **delivered** order, using
`customer_unique_id` as the person-level key. A customer is retained in a
cohort-relative month if they have at least one delivered order in that month.
Revenue is delivered merchandise item price and excludes freight.

The analysis only includes months with delivered activity; it does not create
zero-activity cells for every cohort/month combination. Cohorts near the end of
the dataset have fewer observed follow-up months, so cohort comparisons must
account for exposure time.

Run the cohort analysis and assertions from the repository root:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/05_cohort_analysis.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_cohorts.sql
```

The first result gives cohort size, active customers, retention percentage,
and revenue by cohort and elapsed month. The second summarizes total cohort
revenue and repeat activity.

## Results from the current database

There are **23 delivered-order cohorts**, containing **93,358** distinct
customers at month zero. Their delivered merchandise revenue sums to
**R$ 13,221,498.11**, reconciling to the Phase 8 total.

Across the **23 cohorts** with a fully observable first follow-up month, pooled
month-one retention is **0.45%** (**421 of 93,358 customers**). The denominator
includes cohorts with zero returning customers in month one, rather than only
cohorts with an observed repeat-activity row. An earlier calculation excluded
those zero-activity cohorts and overstated retention at 0.48%; the query and
KPI layer now use the complete eligible cohort population.

The sparse repeat behavior is consistent with the **3.12%** repeat-customer
rate measured in Phase 9. Small and late cohorts can produce volatile
percentages, and the 2018 dataset ends in October, limiting later-month
observation.

## Validation and limitations

`tests/test_cohorts.sql` passed. It checks that cohort revenue reconciles to
delivered item sales, each cohort has full month-zero retention, and active
customer counts do not exceed cohort size.

This is descriptive retention among delivered orders, not a causal estimate
of retention drivers. The source does not identify customer intent, and an
order in the final data period may have insufficient follow-up.
