from __future__ import annotations

from os import environ
from typing import Final, LiteralString

import pandas as pd
import psycopg
from psycopg import sql

QUERIES: Final[dict[str, LiteralString]] = {
    "kpis": "SELECT * FROM analytics.kpi_summary",
    "monthly": """
        SELECT revenue_month, delivered_orders,
               merchandise_revenue_brl::DOUBLE PRECISION
                   AS merchandise_revenue_brl
        FROM analytics.monthly_kpis
        WHERE delivered_orders > 0
        ORDER BY revenue_month
    """,
    "categories": """
        SELECT category,
               SUM(delivered_revenue_brl)::DOUBLE PRECISION
                   AS delivered_revenue_brl,
               SUM(delivered_orders)::INTEGER AS delivered_orders
        FROM analytics.product_summary
        GROUP BY category
        ORDER BY delivered_revenue_brl DESC, category
        LIMIT 10
    """,
    "segments": """
        SELECT rfm_segment, COUNT(*)::INTEGER AS customers,
               SUM(monetary_brl)::DOUBLE PRECISION AS delivered_revenue_brl
        FROM analytics.customer_rfm
        GROUP BY rfm_segment
        ORDER BY customers DESC, rfm_segment
    """,
    "cohorts": """
        WITH cohort_sizes AS (
            SELECT cohort_month, MAX(cohort_size)::INTEGER AS cohort_size
            FROM analytics.customer_cohorts
            WHERE months_since_first_purchase = 0
            GROUP BY cohort_month
        ),
        last_purchase_month AS (
            SELECT MAX(DATE_TRUNC('month', purchase_date)::DATE) AS month
            FROM staging.orders
        ),
        eligible_periods AS (
            SELECT sizes.cohort_month, sizes.cohort_size,
                   periods.months_since_first_purchase
            FROM cohort_sizes sizes
            CROSS JOIN last_purchase_month latest
            CROSS JOIN LATERAL GENERATE_SERIES(
                0,
                (
                    EXTRACT(YEAR FROM AGE(latest.month, sizes.cohort_month)) * 12
                    + EXTRACT(MONTH FROM AGE(latest.month, sizes.cohort_month))
                )::INTEGER
            ) AS periods(months_since_first_purchase)
            WHERE sizes.cohort_month
                  + periods.months_since_first_purchase * INTERVAL '1 month'
                  <= latest.month
        )
        SELECT periods.cohort_month,
               periods.months_since_first_purchase,
               periods.cohort_size,
               COALESCE(cohorts.active_customers, 0)::INTEGER
                   AS active_customers,
               (
                   100.0 * COALESCE(cohorts.active_customers, 0)
                   / NULLIF(periods.cohort_size, 0)
               )::DOUBLE PRECISION AS retention_pct
        FROM eligible_periods periods
        LEFT JOIN analytics.customer_cohorts cohorts
          ON cohorts.cohort_month = periods.cohort_month
         AND cohorts.months_since_first_purchase
             = periods.months_since_first_purchase
        ORDER BY periods.cohort_month,
                 periods.months_since_first_purchase
    """,
    "products": """
        SELECT product_id, category, delivered_orders,
               delivered_revenue_brl::DOUBLE PRECISION
                   AS delivered_revenue_brl,
               average_review_score::DOUBLE PRECISION AS average_review_score
        FROM analytics.product_summary
        WHERE delivered_orders > 0
        ORDER BY delivered_revenue_brl DESC, product_id
        LIMIT 10
    """,
    "delivery_states": """
        SELECT customer_state, COUNT(*)::INTEGER AS delivered_orders,
               AVG(delivery_duration_hours)::DOUBLE PRECISION
                   AS average_delivery_hours,
               (
                   100.0 * COUNT(*) FILTER (WHERE is_late_delivery)
                   / NULLIF(COUNT(*), 0)
               )::DOUBLE PRECISION AS late_delivery_rate_pct
        FROM analytics.delivery_performance
        WHERE delivery_duration_hours >= 0
          AND is_late_delivery IS NOT NULL
        GROUP BY customer_state
        HAVING COUNT(*) >= 100
        ORDER BY average_delivery_hours DESC, customer_state
        LIMIT 12
    """,
    "sellers": """
        SELECT seller_id, state, delivered_orders,
               delivered_revenue_brl::DOUBLE PRECISION
                   AS delivered_revenue_brl
        FROM analytics.seller_summary
        WHERE delivered_orders >= 20
        ORDER BY delivered_revenue_brl DESC, seller_id
        LIMIT 15
    """,
}


def _query_frame(
    connection: psycopg.Connection, query: LiteralString
) -> pd.DataFrame:
    with connection.cursor() as cursor:
        cursor.execute(sql.SQL(query))
        if cursor.description is None:
            raise RuntimeError("Dashboard query did not return a result set")
        rows = cursor.fetchall()
        columns = [column.name for column in cursor.description]
    return pd.DataFrame.from_records(rows, columns=columns)


def load_dashboard_data() -> dict[str, pd.DataFrame]:
    """Load every dashboard dataset from the reusable analytics views."""
    with psycopg.connect(
        host=environ.get("DB_HOST", "localhost"),
        port=int(environ.get("DB_PORT", "5432")),
        dbname=environ.get("DB_NAME", "olist"),
        user=environ.get("DB_USER", "user"),
        password=environ.get("DB_PASSWORD", "password"),
    ) as connection:
        return {
            name: _query_frame(connection, query)
            for name, query in QUERIES.items()
        }
