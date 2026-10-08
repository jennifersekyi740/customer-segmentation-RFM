WITH monthly AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS month,
    ROUND(SUM(sale_price), 2) AS revenue
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status = 'Complete'
    AND date(created_at) < '2026-10-01'
  GROUP BY month
)

SELECT
  month,
  revenue,
  LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
  ROUND(100 * SAFE_DIVIDE(
    revenue - LAG(revenue) OVER (ORDER BY month),
    LAG(revenue) OVER (ORDER BY month)
  ), 1) AS mom_growth_pct
FROM monthly
QUALIFY LAG(revenue) OVER (ORDER BY month) IS NOT NULL
ORDER BY month;
