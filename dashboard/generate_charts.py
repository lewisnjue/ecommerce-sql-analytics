from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt

from dashboard.charts import (
    category_revenue,
    cohort_retention,
    customer_segments,
    delivery_by_state,
    revenue_trend,
    top_products,
    top_sellers,
)
from dashboard.data import load_dashboard_data

OUTPUT_DIRECTORY = Path(__file__).resolve().parent / "images"


def main() -> None:
    data = load_dashboard_data()
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    figures = {
        "monthly_revenue.png": revenue_trend(data["monthly"]),
        "category_revenue.png": category_revenue(data["categories"]),
        "customer_segments.png": customer_segments(data["segments"]),
        "cohort_retention.png": cohort_retention(data["cohorts"]),
        "delivery_by_state.png": delivery_by_state(data["delivery_states"]),
        "top_products.png": top_products(data["products"]),
        "top_sellers.png": top_sellers(data["sellers"]),
    }
    for filename, figure in figures.items():
        output_path = OUTPUT_DIRECTORY / filename
        figure.savefig(output_path, dpi=180, bbox_inches="tight")
        plt.close(figure)
        print(f"Saved {output_path}")


if __name__ == "__main__":
    main()
