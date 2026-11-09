# Local source data

The database loader expects the nine CSV files from the Olist Brazilian
E-Commerce dataset in this directory:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

Obtain the dataset from its original Kaggle source (`olistbr/brazilian-ecommerce`)
and extract those files here. The CSVs and downloaded ZIP are intentionally
excluded from Git; do not commit the source data.

On the first PostgreSQL initialization with an empty Docker data volume,
`schema/init.sh` loads the CSVs into the `public` source tables. Docker only
runs initialization scripts for a new database volume. The existing project
database may already be populated; do not remove its volume just to reload the
files. For an existing database, follow the staging refresh instructions in
the main [README](../README.md).
