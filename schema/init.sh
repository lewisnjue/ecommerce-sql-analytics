#!/bin/bash
set -e

echo "Starting database schema creation..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /opt/schema/tables.sql

echo "Loading data from CSV files..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy product_category_name_translation FROM '/opt/data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy customers FROM '/opt/data/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy sellers FROM '/opt/data/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy geolocation(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state) FROM '/opt/data/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy products FROM '/opt/data/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy orders FROM '/opt/data/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy order_items FROM '/opt/data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy order_payments FROM '/opt/data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy order_reviews FROM '/opt/data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true);"

echo "Updating database statistics (ANALYZE)..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ANALYZE;"

echo "Initialization completed successfully!"
