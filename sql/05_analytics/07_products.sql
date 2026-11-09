-- Phase 13: product sales, pricing, ratings, rankings, and Pareto contribution.
WITH product_sales AS (
    SELECT p.product_id,
           COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS category,
           COUNT(oi.order_item_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_item_rows,
           COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_orders,
           SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered')
               AS merchandise_revenue_brl,
           AVG(oi.price_brl) FILTER (WHERE o.status = 'delivered')
               AS average_selling_price_brl
    FROM staging.products p
    LEFT JOIN staging.order_items oi ON oi.product_id = p.product_id
    LEFT JOIN staging.orders o
        ON o.order_id = oi.order_id AND o.status = 'delivered'
    GROUP BY p.product_id,
             COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
),
product_reviews AS (
    SELECT x.product_id, AVG(r.review_score)::NUMERIC AS average_review_score,
           COUNT(*) AS review_count
    FROM (
        SELECT DISTINCT oi.product_id, oi.order_id
        FROM staging.order_items oi
    ) x
    JOIN staging.order_reviews r ON r.order_id = x.order_id
    GROUP BY x.product_id
)
SELECT ps.product_id, ps.category, ps.delivered_item_rows, ps.delivered_orders,
       COALESCE(ps.merchandise_revenue_brl, 0) AS merchandise_revenue_brl,
       ROUND(ps.average_selling_price_brl, 2) AS average_selling_price_brl,
       ROUND(pr.average_review_score, 2) AS average_review_score,
       COALESCE(pr.review_count, 0) AS review_count,
       RANK() OVER (ORDER BY COALESCE(ps.merchandise_revenue_brl, 0) DESC)
           AS revenue_rank,
       RANK() OVER (ORDER BY ps.delivered_item_rows DESC) AS volume_rank
FROM product_sales ps
LEFT JOIN product_reviews pr USING (product_id)
ORDER BY merchandise_revenue_brl DESC, ps.product_id
LIMIT 50;

-- Category performance with review performance at product/order grain.
WITH product_order_reviews AS (
    SELECT DISTINCT oi.product_id, oi.order_id, r.review_id, r.review_score
    FROM staging.order_items oi
    JOIN staging.order_reviews r ON r.order_id = oi.order_id
),
category_reviews AS (
    SELECT COALESCE(
               p.category_name_english,
               p.category_name,
               '[Uncategorized]'
           ) AS category,
           AVG(por.review_score)::NUMERIC AS average_review_score,
           COUNT(*) AS review_observations
    FROM product_order_reviews por
    JOIN staging.products p ON p.product_id = por.product_id
    GROUP BY COALESCE(
                 p.category_name_english,
                 p.category_name,
                 '[Uncategorized]'
             )
),
category_sales AS (
    SELECT COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS category,
           COUNT(*) AS delivered_item_rows,
           SUM(oi.price_brl) AS merchandise_revenue_brl,
           AVG(oi.price_brl) AS average_item_price_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
    GROUP BY COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
)
SELECT cs.category, cs.delivered_item_rows, cs.merchandise_revenue_brl,
       ROUND(cs.average_item_price_brl, 2) AS average_item_price_brl,
       ROUND(cr.average_review_score, 2) AS average_review_score,
       cr.review_observations,
       RANK() OVER (ORDER BY cs.merchandise_revenue_brl DESC) AS revenue_rank
FROM category_sales cs
LEFT JOIN category_reviews cr ON cr.category = cs.category
ORDER BY cs.merchandise_revenue_brl DESC;

-- Sales quartiles versus satisfaction. Quartiles are product-level rank bins;
-- deterministic product IDs break ties at the quartile boundaries.
WITH product_sales AS (
    SELECT p.product_id,
           COUNT(oi.order_item_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_units,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS revenue_brl
    FROM staging.products p
    LEFT JOIN staging.order_items oi ON oi.product_id = p.product_id
    LEFT JOIN staging.orders o ON o.order_id = oi.order_id
    GROUP BY p.product_id
),
product_reviews AS (
    SELECT por.product_id, AVG(por.review_score)::NUMERIC AS average_score
    FROM (
        SELECT DISTINCT oi.product_id, r.review_id, r.order_id, r.review_score
        FROM staging.order_items oi
        JOIN staging.order_reviews r ON r.order_id = oi.order_id
    ) por
    GROUP BY por.product_id
),
ranked_products AS (
    SELECT ps.*, pr.average_score,
           NTILE(4) OVER (ORDER BY ps.delivered_units DESC, ps.product_id)
               AS sales_quartile
    FROM product_sales ps
    LEFT JOIN product_reviews pr USING (product_id)
)
SELECT CASE sales_quartile
           WHEN 1 THEN 'Highest sales quartile'
           WHEN 4 THEN 'Lowest sales quartile'
           ELSE 'Middle sales quartiles'
       END AS sales_band,
       CASE
           WHEN average_score IS NULL THEN 'No review score'
           WHEN average_score < 3 THEN 'Poor average rating (<3)'
           WHEN average_score >= 4 THEN 'High average rating (>=4)'
           ELSE 'Average rating (3 to <4)'
       END AS rating_band,
       COUNT(*) AS products,
       ROUND(AVG(delivered_units), 2) AS average_delivered_units,
       ROUND(AVG(revenue_brl), 2) AS average_revenue_brl,
       ROUND(AVG(average_score), 2) AS average_product_rating
FROM ranked_products
GROUP BY sales_band, rating_band
ORDER BY sales_band, rating_band;

-- Revenue Pareto: cumulative product sales contribution in descending order.
WITH product_sales AS (
    SELECT p.product_id, SUM(oi.price_brl) AS revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
    GROUP BY p.product_id
),
pareto AS (
    SELECT product_id, revenue_brl,
           SUM(revenue_brl) OVER (
               ORDER BY revenue_brl DESC, product_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue_brl,
           SUM(revenue_brl) OVER () AS total_revenue_brl
    FROM product_sales
)
SELECT COUNT(*) FILTER (
           WHERE cumulative_revenue_brl - revenue_brl < 0.8 * total_revenue_brl
       ) AS products_needed_to_reach_80pct_revenue,
       ROUND(MAX(total_revenue_brl), 2) AS total_revenue_brl,
       ROUND(
           100.0 * COUNT(*) FILTER (
               WHERE cumulative_revenue_brl - revenue_brl < 0.8 * total_revenue_brl
           ) / COUNT(*),
           2
       ) AS pct_products_needed_for_80pct
FROM pareto;
