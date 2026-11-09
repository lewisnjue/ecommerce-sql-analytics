from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd
import psycopg
import streamlit as st

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

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

st.set_page_config(
    page_title="Olist E-Commerce Analytics",
    page_icon="📊",
    layout="wide",
)


@st.cache_data(ttl=900)
def get_dashboard_data() -> dict[str, pd.DataFrame]:
    return load_dashboard_data()


st.title("Olist E-Commerce Analytics")
st.caption(
    "PostgreSQL-backed reporting. Sales represent delivered merchandise prices "
    "and exclude freight."
)

if st.sidebar.button("Refresh dashboard data"):
    get_dashboard_data.clear()

try:
    dashboard_data = get_dashboard_data()
except (psycopg.Error, ValueError) as error:
    st.error(f"Could not load dashboard data from PostgreSQL: {error}")
    st.info(
        "Start the database with `docker compose up -d`, then confirm the "
        "DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD environment "
        "variables if your local connection settings differ."
    )
    st.stop()

kpis = dashboard_data["kpis"].iloc[0]
page = st.sidebar.radio(
    "Analytics section",
    ("Executive overview", "Customers", "Products", "Operations"),
)

if page == "Executive overview":
    st.subheader("Executive overview")
    metric_columns = st.columns(4)
    metric_columns[0].metric(
        "Delivered merchandise sales",
        f"R$ {float(kpis['total_revenue_brl']):,.2f}",
    )
    metric_columns[1].metric(
        "Delivered orders", f"{int(kpis['delivered_orders']):,}"
    )
    metric_columns[2].metric(
        "Delivered customers", f"{int(kpis['delivered_customers']):,}"
    )
    metric_columns[3].metric(
        "Average order value",
        f"R$ {float(kpis['average_order_value_brl']):,.2f}",
    )
    st.caption(
        f"Snapshot date: {kpis['as_of_date']} · "
        f"Late-delivery rate: {float(kpis['late_delivery_rate_pct']):.2f}% · "
        f"Average review score: {float(kpis['average_review_score']):.3f}/5"
    )
    st.pyplot(revenue_trend(dashboard_data["monthly"]), clear_figure=True)
    st.pyplot(category_revenue(dashboard_data["categories"]), clear_figure=True)

elif page == "Customers":
    st.subheader("Customer analytics")
    left, right = st.columns(2)
    with left:
        st.pyplot(
            customer_segments(dashboard_data["segments"]), clear_figure=True
        )
    with right:
        st.write(
            "Cohort retention is based on delivered purchases. Blank cells "
            "represent months beyond the dataset's observation window."
        )
        st.pyplot(
            cohort_retention(dashboard_data["cohorts"]), clear_figure=True
        )

elif page == "Products":
    st.subheader("Product analytics")
    left, right = st.columns(2)
    with left:
        st.pyplot(
            category_revenue(dashboard_data["categories"]), clear_figure=True
        )
    with right:
        st.pyplot(top_products(dashboard_data["products"]), clear_figure=True)
    st.dataframe(
        dashboard_data["products"],
        hide_index=True,
        column_config={
            "delivered_revenue_brl": st.column_config.NumberColumn(
                "Delivered sales (BRL)", format="R$ %.2f"
            ),
            "average_review_score": st.column_config.NumberColumn(
                "Average review score", format="%.3f"
            ),
        },
        width="stretch",
    )

else:
    st.subheader("Operations")
    left, right = st.columns(2)
    with left:
        st.pyplot(
            delivery_by_state(dashboard_data["delivery_states"]),
            clear_figure=True,
        )
    with right:
        st.pyplot(top_sellers(dashboard_data["sellers"]), clear_figure=True)
    st.caption(
        "Delivery state comparisons include states with at least 100 eligible "
        "deliveries. Seller sales use the seller's delivered order items."
    )

st.divider()
st.caption(
    "Metrics come from the analytics schema. RFM, cohort, delivery, and "
    "product/seller views have their phase-specific definitions in docs/."
)
