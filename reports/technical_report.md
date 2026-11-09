# Technical Report — Olist Brazilian E-Commerce Analytics

## Dataset and scope

The project analyzes the Olist Brazilian e-commerce dataset, a relational
extract of nine CSV entities: customers, sellers, geolocation, products,
category translations, orders, order items, payments, and reviews. The current
loaded snapshot contains 99,441 orders, 112,650 order items, 96,096 distinct
people (`customer_unique_id`), 32,951 products, 3,095 sellers, and 99,224
review rows. The available order-purchase history runs from 2016-09-04 through
2018-10-17.

The work is descriptive. Its primary sales measure is delivered item
`price_brl`, excluding freight; it is not accounting revenue or profit.

## Architecture and database design

The project uses PostgreSQL 14 in Docker Compose. Raw source tables are loaded
into the PostgreSQL `public` schema; `staging` holds typed, consistently named
analysis inputs; `analytics` contains reusable regular views. The architecture
is therefore `public` → `staging` → `analytics`, rather than a separate schema
named `raw`.

The source schema is defined in [schema/tables.sql](../schema/tables.sql).
Primary keys include the order, customer, product, seller, and category keys;
order items, payments, and reviews use composite keys. Foreign keys connect
orders to customers, items to orders/products/sellers, and payments/reviews to
orders. ZIP prefixes are not unique geographies, so geolocation is indexed but
not modeled as a foreign-key dimension. The raw schema also restricts order
status and review scores with checks.

The nine staging tables preserve source lineage while standardizing identifiers
and columns. The eight core analytics views summarize customers, products,
sellers, monthly revenue, RFM, cohorts, delivery, and monthly KPIs; the
one-row `analytics.kpi_summary` adds consistent portfolio-level snapshot
metrics. They are regular views, so they reflect current staging data rather
than stored snapshots.

## Data ingestion and staging

`compose.yml` starts the database and mounts the local `data/` and `schema/`
directories. On initialization of a new PostgreSQL data volume,
`schema/init.sh` creates the source tables and uses `psql \copy` to load the
CSV files. The source files are local inputs and are excluded from Git. The
container does not rerun its initialization scripts against an already
initialized volume.

After raw data is available, `sql/03_staging/01_create_staging_tables.sql`
defines staging tables and `sql/03_staging/02_refresh_staging.sql` rebuilds
their rows in one transaction. The refresh trims fixed-width identifiers,
standardizes column names, enriches category translations, normalizes blank
review comments to NULL, and derives analysis dates, elapsed delivery hours,
product volume, item totals, and explicit data-quality flags. It leaves raw
tables unchanged and preserves suspicious source values instead of silently
correcting or dropping them.

The staging test verifies source/staging row-count agreement. The current
snapshot has 99,441 staged customers, 99,441 orders, 112,650 order items,
103,886 payments, 99,224 reviews, 32,951 products, 3,095 sellers, 1,000,163
geolocation rows, and 71 category translations.

## Data quality and cleaning decisions

Quality queries in `sql/04_quality/` investigate nulls, duplicates,
referential integrity, values, and chronology before transformations are
applied. They found no duplicate declared keys or orphan rows among the tested
relationships. Other findings are retained and documented rather than treated
as reasons to discard source rows:

- 261,831 excess repeated geolocation observations across repeated full-record
  groups; the correct geographic deduplication grain is not established.
- 13 products lack an English category translation; their source category is
  retained.
- 1,359 carrier handoffs precede approval, 166 precede purchase, 23 deliveries
  precede carrier handoff, and 74 reviews precede purchase.
- Eight orders marked delivered have no customer delivery timestamp.
- Two payments have fewer than one installment despite positive payment
  values.
- Review comments are often absent; empty strings are normalized in staging,
  but missing comments are not imputed.

These are investigation results, not proof that every row is valid or
representative. The exact definitions and decisions are in
[docs/data_quality_report.md](../docs/data_quality_report.md).

## SQL methodology and analytical models

The analytical layer uses explicit grains to control one-to-many joins:

- Customer metrics group people by `customer_unique_id`, not the
  order-specific `customer_id`.
- Sales aggregate item prices at item/order grain before joining to other
  one-to-many sources; payment rows are not summed as sales.
- Product and seller review links deduplicate at product/order/review and
  seller/order/review grains.
- Seller delivery performance counts distinct seller/order pairs.
- Cohorts use the first delivered-purchase month; revenue is delivered item
  price. Retention uses eligible cohorts, including zero-return cohorts in the
  denominator.
- RFM and seller tiers use documented, dataset-relative rank rules. The
  customer lifetime-value estimate is a qualified 12-month spending proxy,
  not a forecast or profit measure.

Across the SQL phases, queries demonstrate joins, grouping, conditional
aggregation, CTEs, scalar and correlated subqueries, date arithmetic,
percentiles, `FILTER`, windowed ranks and running totals, rolling averages,
`LAG`/`LEAD`, and Pareto calculations. Reusable analysis is exposed through
views rather than being duplicated in the dashboard.

## Performance and testing

The measured workload filters delivered orders for August 2018 and joins to
order items. On this database, the median of three warm runs moved from
57.972 ms to 43.017 ms after adding
`staging.idx_stg_orders_status_month_order(status, purchase_month, order_id)`,
an approximately 25.8% reduction. The post-index plan used an index-only scan
for matching orders; the index occupied 7,544 kB. This result is specific to
the data, PostgreSQL version, container, and cache state.

Phase-specific SQL assertions cover staging, data quality, relationships,
exploration, revenue, customers, segmentation, cohorts, the CLV proxy,
products, sellers, delivery, reviews, advanced SQL, views, performance, and
KPIs. The consolidated runner is `bash tests/run_all.sh`; it creates the
reporting views and measured index before running the assertions. Test
definitions and expected behavior are in [docs/sql_testing.md](../docs/sql_testing.md).

The Streamlit app in `dashboard/` reads the `analytics` views using Psycopg.
Matplotlib and Seaborn chart functions are shared between the app and
`dashboard/generate_charts.py`, which exports seven PNG files to
`dashboard/images/`. Python dependencies are managed by `uv` in `pyproject.toml`
and `uv.lock`.

## Reproduction

From the repository root, with the local dataset files available in `data/`:

```bash
docker compose up -d
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/03_staging/01_create_staging_tables.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/03_staging/02_refresh_staging.sql
bash tests/run_all.sh
uv sync
uv run python -m dashboard.generate_charts
uv run streamlit run dashboard/app.py
```

The database initialization step runs only for a newly initialized Docker
volume; an existing loaded database can proceed directly to the staging
refresh. Local Compose credentials are for development only. Dashboard
connection settings can be overridden with `DB_HOST`, `DB_PORT`, `DB_NAME`,
`DB_USER`, and `DB_PASSWORD`; see [dashboard/README.md](../dashboard/README.md).

## Limitations

The data ends in 2018 and the final months have incomplete observation. No
complete accounting ledger, margins, operating costs, refunds, or validated
future-outcome labels are available. Geographic and entity averages can be
unstable at low sample sizes. Customer, delivery, and review associations are
observational and do not establish causal effects. RFM segments, seller
quartiles, cohorts, and the CLV proxy are methodological choices that must be
reviewed before operational use.
