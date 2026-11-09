-- Phase 14: seller performance at seller/order grain.
WITH seller_order AS (
    SELECT s.seller_id, s.state,
           o.order_id, o.status, o.delivery_duration_hours,
           SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered')
               AS delivered_revenue_brl,
           COUNT(oi.order_item_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_items
    FROM staging.sellers s
    LEFT JOIN staging.order_items oi ON oi.seller_id = s.seller_id
    LEFT JOIN staging.orders o ON o.order_id = oi.order_id
    GROUP BY s.seller_id, s.state, o.order_id, o.status,
             o.delivery_duration_hours
),
seller_reviews AS (
    SELECT seller_id, AVG(review_score)::NUMERIC AS average_review_score,
           COUNT(*) AS review_count
    FROM (
        SELECT DISTINCT oi.seller_id, r.review_id, r.order_id, r.review_score
        FROM staging.order_items oi
        JOIN staging.order_reviews r ON r.order_id = oi.order_id
    ) review_events
    GROUP BY seller_id
),
seller_metrics AS (
    SELECT seller_id, state,
           COUNT(DISTINCT order_id) AS associated_orders,
           COUNT(DISTINCT order_id) FILTER (WHERE status = 'delivered')
               AS delivered_orders,
           COUNT(DISTINCT order_id) FILTER (WHERE status = 'canceled')
               AS canceled_orders,
           COALESCE(SUM(delivered_revenue_brl), 0) AS delivered_revenue_brl,
           COALESCE(SUM(delivered_items), 0) AS delivered_items,
           AVG(delivery_duration_hours)
               FILTER (WHERE status = 'delivered'
                       AND delivery_duration_hours >= 0)
               AS average_delivery_hours
    FROM seller_order
    GROUP BY seller_id, state
),
ranked_sellers AS (
    SELECT sm.*, sr.average_review_score, COALESCE(sr.review_count, 0) AS review_count,
           ROUND(100.0 * canceled_orders / NULLIF(associated_orders, 0), 2)
               AS cancellation_rate_pct,
           ROUND(delivered_revenue_brl / NULLIF(delivered_orders, 0), 2)
               AS revenue_per_delivered_order_brl,
           NTILE(4) OVER (
               ORDER BY delivered_revenue_brl DESC, seller_id
           ) AS performance_quartile
    FROM seller_metrics sm
    LEFT JOIN seller_reviews sr USING (seller_id)
)
SELECT seller_id, state, associated_orders, delivered_orders, canceled_orders,
       cancellation_rate_pct, delivered_items, delivered_revenue_brl,
       revenue_per_delivered_order_brl,
       ROUND(average_delivery_hours::NUMERIC, 2) AS average_delivery_hours,
       ROUND(average_review_score, 2) AS average_review_score, review_count,
       CASE performance_quartile
           WHEN 1 THEN 'Top performers'
           WHEN 2 THEN 'Strong performers'
           WHEN 3 THEN 'Average performers'
           ELSE 'Underperformers'
       END AS seller_tier
FROM ranked_sellers
ORDER BY delivered_revenue_brl DESC, seller_id
LIMIT 50;

-- Tier-level summary, including sellers with no delivered sales.
WITH seller_sales AS (
    SELECT s.seller_id,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS revenue_brl
    FROM staging.sellers s
    LEFT JOIN staging.order_items oi ON oi.seller_id = s.seller_id
    LEFT JOIN staging.orders o ON o.order_id = oi.order_id
    GROUP BY s.seller_id
),
seller_tiers AS (
    SELECT *, NTILE(4) OVER (ORDER BY revenue_brl DESC, seller_id) AS quartile
    FROM seller_sales
)
SELECT CASE quartile
           WHEN 1 THEN 'Top performers'
           WHEN 2 THEN 'Strong performers'
           WHEN 3 THEN 'Average performers'
           ELSE 'Underperformers'
       END AS seller_tier,
       COUNT(*) AS sellers,
       SUM(revenue_brl) AS delivered_revenue_brl,
       ROUND(AVG(revenue_brl), 2) AS average_seller_revenue_brl
FROM seller_tiers
GROUP BY quartile
ORDER BY quartile;
