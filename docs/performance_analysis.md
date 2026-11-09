# Phase 19 — Indexing & Query Performance

The measured workload filters delivered orders to a single purchase month and
joins their items to sum merchandise revenue. The query is saved in
[sql/09_performance/01_explain_examples.sql](../sql/09_performance/01_explain_examples.sql);
the index definition is in
[sql/08_indexes/01_analytical_indexes.sql](../sql/08_indexes/01_analytical_indexes.sql).

Benchmark on the populated staging tables:

| State | Plan | Warm execution times | Median |
|---|---|---:|---:|
| Before index | Parallel sequential scans of orders and order items, parallel hash join | 57.462, 67.730, 57.972 ms | 57.972 ms |
| After index | Index-only scan of filtered orders, hash join, sequential scan of order items | 43.017, 43.412, 40.440 ms | 43.017 ms |

The median decreased by approximately **25.8%** for this selective monthly
workload. The composite B-tree index on
`staging.orders(status, purchase_month, order_id)` supports the frequently
used status/month filter and provides the join key. The after-index plan
scanned 6,351 matching orders from the index with zero heap fetches. PostgreSQL
still scanned `order_items` sequentially; for this table size and join shape,
that was cheaper than many individual lookups. The index occupied **7,544 kB**
on the measured database.

The index is deliberately limited to a workload with demonstrated benefit.
The timing is specific to this dataset, PostgreSQL version, container, and
cache state; it is not a general latency guarantee. Extra indexes consume
storage and add work to staging writes, so other foreign-key/date indexes
should be justified with their own workload plans rather than added
automatically.

Reproduce on a fresh populated staging database by running the explain query
three times before creating the index, then creating the index and running it
three times again. Keep the staging data and query identical for both states.
The index and analysis were run against the existing Docker database.

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/09_performance/01_explain_examples.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/08_indexes/01_analytical_indexes.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/09_performance/01_explain_examples.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_performance.sql
```

`tests/test_performance.sql` passed and confirms the benchmark revenue equals
the monthly analytics view and the measured index exists.
