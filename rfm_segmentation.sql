WITH orders_cleaned AS (
  SELECT
  user_id,
  order_id,
  created_at,
  sale_price

 FROM `bigquery-public-data.thelook_ecommerce.order_items`
 WHERE status = 'Complete'
  AND date(created_at) < '2026-10-01'
 ),

 rfm_base AS (
  SELECT
  user_id,
  DATE_DIFF(DATE_ADD((SELECT DATE(MAX(created_at)) FROM orders_cleaned), INTERVAL 1 DAY), 
  DATE(MAX(created_at)), DAY
  ) AS recency_days,
  COUNT(DISTINCT order_id) AS frequency,
  ROUND(SUM(sale_price),2) AS monetary
FROM orders_cleaned
GROUP BY user_id
 ),

  rfm_scores AS (
    SELECT
    user_id,
    recency_days,
    frequency,  
    monetary,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score

     FROM rfm_base ),

  rfm_segments AS (
    SELECT *,
    CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
    WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
    WHEN r_score >= 3 AND (f_score >= 3 OR m_score >= 3) THEN 'Potentially At Risk'
    WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
    WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
    ELSE 'About To Sleep'
    END AS segment
    FROM rfm_scores


  ),
  segment_summary AS (
 SELECT 
 segment,
 COUNT(*) AS customers,
 ROUND(SUM(monetary) ,2) AS total_revenue,
 ROUND(AVG(monetary) , 2) AS avg_spend,
 ROUND(AVG(recency_days), 0) AS avg_recency_days,
ROUND(AVG(frequency), 2) AS avg_orders

 FROM rfm_segments
 GROUP BY segment)

  


 SELECT 
 segment,
 customers,
 avg_recency_days,
 avg_orders,

 ROUND(100 * customers / (SELECT SUM(customers) FROM segment_summary) ,1) AS pct_customers,
 total_revenue,
 ROUND(100 * total_revenue / (SELECT SUM(total_revenue) FROM segment_summary) ,1) AS pct_revenue,
 FROM segment_summary
 ORDER BY total_revenue DESC;
 
 
