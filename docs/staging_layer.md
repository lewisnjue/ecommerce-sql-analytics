# Phase 6 — Staging Layer

## Purpose and source

The staging schema provides consistently typed, named, and traceable tables for
analysis. It is built from the existing raw tables in PostgreSQL's `public`
schema. Raw tables remain unchanged; staging refreshes replace only rows in the
`staging` schema.

Run these commands from the repository root:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/03_staging/01_create_staging_tables.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/03_staging/02_refresh_staging.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_staging.sql
```

The refresh is transactional and repeatable: it truncates and reloads all
staging tables together, so a failed insert rolls back the refresh. Run the
table-creation script before the refresh script.

## Transformations

* Trim fixed-width identifiers and ZIP prefixes into `VARCHAR` values.
* Use consistent descriptive column names, such as `status`, `purchased_at`,
  `name_length`, and `description_length`; correct the source's
  `product_name_lenght` and `product_description_lenght` typos in staging.
* Keep source timestamps as `TIMESTAMP WITHOUT TIME ZONE`. The source has no
  timezone offset, so staging does not guess or apply a timezone conversion.
* Preserve source keys for lineage. Geolocation rows retain their raw-table
  surrogate as `source_geolocation_id`, since ZIP prefixes and location records
  are not unique.
* Enrich products with an English category using a left join. Portuguese source
  category values and products without a translation remain available.
* Normalize blank review comments to NULL after trimming whitespace. Existing
  NULL comments remain NULL; no review rows are removed.
* Derive order purchase date/month and delivery duration; product volume;
  item price plus freight; payment/review timing; and explicit flags for the
  investigated chronology, status, installment, and delivery issues.
* Preserve suspicious values and dates in their source columns. Flags expose
  issues for later analysis instead of silently correcting them.
* Keep all repeated geolocation records. The correct deduplication grain has
  not been established, and the original rows remain traceable.

For `is_late_delivery`, a value is produced only for delivered orders that have
an actual customer-delivery timestamp. `delivery_duration_hours` is derived
from the recorded purchase and delivery timestamps, including negative values
where the source chronology is inconsistent; the corresponding boolean flags
make those records discoverable.

## Validation results

`tests/test_staging.sql` asserts that all staged row counts match the raw table
counts and that the Phase 5 anomalies remain visible after transformation.
Against the current database snapshot, all assertions pass:

| Staging table | Rows |
|---|---:|
| `staging.customers` | 99,441 |
| `staging.product_category_translations` | 71 |
| `staging.sellers` | 3,095 |
| `staging.geolocation` | 1,000,163 |
| `staging.products` | 32,951 |
| `staging.orders` | 99,441 |
| `staging.order_items` | 112,650 |
| `staging.order_payments` | 103,886 |
| `staging.order_reviews` | 99,224 |

The staged quality flags retain the investigated counts: 1,359 carrier
timestamps before approval, 166 carrier timestamps before purchase, 23
deliveries before carrier handoff, 8 delivered orders without a delivery
timestamp, 6 non-delivered orders with a delivery timestamp, 74 reviews created
before purchase, 13 untranslated products, and 2 invalid installment rows.
Repeated geolocation rows were not dropped. Empty review titles/messages are
normalized to NULL (87,658 and 58,256 staged NULLs respectively).
