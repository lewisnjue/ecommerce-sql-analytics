# Phase 20 — SQL Testing

The project has focused SQL assertions for each analytical phase plus
cross-cutting tests for data quality and relationships. The suite is run from
the repository root with:

```bash
bash tests/run_all.sh
```

The PostgreSQL container must be running and staging must already be created
and refreshed. The runner idempotently creates/replaces the reporting views
and measured performance index, then runs the SQL test files in order.

| Test | Expected result |
|---|---|
| `test_staging.sql` | Each of the nine staging row counts matches its raw source; documented anomalies and nullable comment normalization remain represented by their staging flags/values. |
| `test_data_quality.sql` | Required staged values are non-NULL; review/item values are valid; arithmetic and chronology flags exactly reflect staged values. Known anomalies are preserved rather than treated as a failed test. |
| `test_relationships.sql` | 0 duplicate staged primary/composite keys and 0 unresolved staged foreign-key relationships. |
| `test_exploration.sql` | Population and aggregate calculations reconcile to their source tables. |
| `test_revenue.sql` | Delivered merchandise revenue and related monthly/item rollups reconcile. |
| `test_customers.sql`, `test_customer_segmentation.sql`, `test_cohorts.sql`, `test_clv.sql` | Customer grain, segmentation bounds, cohort revenue, and the qualified CLV proxy calculations pass their assertions. |
| `test_products.sql`, `test_sellers.sql`, `test_delivery.sql`, `test_customer_satisfaction.sql` | Product/seller revenue, delivery coverage/classification, and review score domain/associations pass their checks. |
| `test_advanced_sql.sql` | Monthly running revenue and product revenue reconcile; Pareto cumulative share reaches 100%; seller top-N bounds hold. |
| `test_analytics_views.sql` | Entity coverage and delivered sales reconcile across customer, product, seller, monthly revenue, and KPI views; cohort, RFM, and rate bounds pass. |
| `test_performance.sql` | The measured month-level revenue matches the analytics view and its supporting index exists. |
| `test_kpis.sql` | Snapshot revenue, AOV, retention, and delivery rate reconcile to source values; percentage bounds and leader labels are valid. |

The full suite completed successfully against the populated PostgreSQL
database. Most individual test files finish with a `... checks passed` result;
staging additionally prints the entity counts and preserved anomaly counts.
The assertions are dataset-aware: known source quality anomalies are
documented and tested for faithful flagging, not silently discarded to force
zero results.
