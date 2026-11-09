# Streamlit dashboard

The dashboard reads the PostgreSQL reporting views created by
`sql/07_views/01_create_analytics_views.sql` and
`sql/07_views/02_create_kpi_summary.sql`. It does not query raw tables for its
primary measures.

## Run locally

Start PostgreSQL, install the project dependencies, and launch the app from the
repository root:

```bash
docker compose up -d
uv sync
uv run streamlit run dashboard/app.py
```

By default the app connects to the local Compose database using
`localhost:5432`, database `olist`, user `user`, and password `password`.
Override those local-development defaults with `DB_HOST`, `DB_PORT`, `DB_NAME`,
`DB_USER`, and `DB_PASSWORD` environment variables when needed. The dashboard
caches query results for 15 minutes; use **Refresh dashboard data** to clear
the cache.

The app has executive, customer, product, and operations sections. Delivered
sales are merchandise item prices and exclude freight; they are not accounting
revenue or profit. The cohort view excludes periods outside the observation
window. State delivery rankings require at least 100 eligible deliveries.

## Export static charts

To regenerate the image deliverables from the current database:

```bash
uv run python -m dashboard.generate_charts
```

The script writes seven PNG charts to `dashboard/images/`. The chart code is
shared with the Streamlit app and uses Matplotlib and Seaborn.
