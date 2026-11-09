# E-Commerce SQL Analytics

A PostgreSQL project for exploring the Brazilian Olist e-commerce dataset with
raw SQL. The project is being built phase by phase according to
[ROADMAP.md](ROADMAP.md).

## Start the database

From the repository root, start the PostgreSQL 14 container:

```bash
docker compose up -d
```

On the first start with an empty Docker volume, `schema/init.sh` creates the
tables and loads the CSV files in `data/`. Connect to the running database with:

```bash
docker compose exec db psql -U user -d olist
```

The credentials in `compose.yml` are for local development only.

## Phase 5: Data quality investigation

The raw data investigation and findings are documented in
[docs/data_quality_report.md](docs/data_quality_report.md). The SQL is organized
by check type in [`sql/04_quality/`](sql/04_quality/). To run a query file from
the repository root, for example:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/04_quality/01_null_checks.sql
```

The complete set of Phase 5 scripts is:

* `01_null_checks.sql`
* `02_duplicate_checks.sql`
* `03_referential_integrity.sql`
* `04_value_validation.sql`
* `05_date_validation.sql`

These queries inspect the loaded data without modifying or cleaning it.
