import os
import shutil
import urllib.request
import zipfile
from pathlib import Path

import psycopg


DATASET_URL = "https://www.kaggle.com/api/v1/datasets/download/olistbr/brazilian-ecommerce"
DATASET_NAME = "olist_brazilian_ecommerce"
CSV_FILES = (
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
)
IMPORT_ORDER = (
    ("customers", "olist_customers_dataset.csv"),
    ("geolocation", "olist_geolocation_dataset.csv"),
    ("sellers", "olist_sellers_dataset.csv"),
    ("products", "olist_products_dataset.csv"),
    ("product_category_name_translation", "product_category_name_translation.csv"),
    ("orders", "olist_orders_dataset.csv"),
    ("order_items", "olist_order_items_dataset.csv"),
    ("order_payments", "olist_order_payments_dataset.csv"),
    ("order_reviews", "olist_order_reviews_dataset.csv"),
)


def ensure_dataset(data_dir: Path) -> None:
    missing_files = [name for name in CSV_FILES if not (data_dir / name).is_file()]
    if not missing_files:
        print("All dataset CSV files are already extracted.", flush=True)
        return

    archive_path = data_dir / "brazilian-ecommerce.zip"
    if not archive_path.is_file():
        print("Downloading the Brazilian E-Commerce dataset...", flush=True)
        request = urllib.request.Request(
            DATASET_URL,
            headers={"User-Agent": "ecommerce-sql-analytics/1.0"},
        )
        with urllib.request.urlopen(request, timeout=120) as response:
            with archive_path.open("wb") as archive_file:
                shutil.copyfileobj(response, archive_file)

    print("Extracting dataset CSV files...", flush=True)
    wanted_files = set(CSV_FILES)
    extracted_files = set()
    with zipfile.ZipFile(archive_path) as archive:
        for member in archive.infolist():
            basename = Path(member.filename).name
            if basename not in wanted_files:
                continue
            destination = data_dir / basename
            with archive.open(member) as source, destination.open("wb") as output:
                shutil.copyfileobj(source, output)
            extracted_files.add(basename)

    absent_files = wanted_files - extracted_files
    if absent_files:
        raise RuntimeError(
            "Dataset archive is missing expected CSV files: "
            + ", ".join(sorted(absent_files))
        )


def import_dataset(data_dir: Path) -> None:
    connection = psycopg.connect()
    try:
        with connection:
            with connection.cursor() as cursor:
                cursor.execute(Path("/app/schema.sql").read_text())
                cursor.execute(
                    "SELECT 1 FROM olist._dataset_imports WHERE dataset_name = %s",
                    (DATASET_NAME,),
                )
                if cursor.fetchone():
                    print("Dataset is already loaded; skipping import.", flush=True)
                    return

                for table_name, filename in IMPORT_ORDER:
                    file_path = data_dir / filename
                    print(f"Loading {filename} into olist.{table_name}...", flush=True)
                    columns = (
                        " (review_id, order_id, review_score, review_comment_title, "
                        "review_comment_message, review_creation_date, review_answer_timestamp)"
                        if table_name == "order_reviews"
                        else ""
                    )
                    with file_path.open("rb") as csv_file:
                        with cursor.copy(
                            f"COPY olist.{table_name}{columns} FROM STDIN "
                            "WITH (FORMAT CSV, HEADER TRUE)"
                        ) as copy:
                            while chunk := csv_file.read(1024 * 1024):
                                copy.write(chunk)

                cursor.execute(
                    "INSERT INTO olist._dataset_imports (dataset_name) VALUES (%s)",
                    (DATASET_NAME,),
                )
        print("Dataset loaded successfully into schema olist.", flush=True)
    finally:
        connection.close()


def main() -> None:
    data_dir = Path(os.environ.get("DATA_DIR", "/data"))
    data_dir.mkdir(parents=True, exist_ok=True)
    ensure_dataset(data_dir)
    import_dataset(data_dir)


if __name__ == "__main__":
    main()