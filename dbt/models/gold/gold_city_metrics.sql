{{
  config(
    materialized='table',
    tags=['gold', 'city', 'metrics']
  )
}}

/*
Gold Layer: City-Level Metrics

Aggregates booking metrics at the city level for business intelligence.
Provides year-to-date statistics and trends.
*/

WITH city_bookings AS (
    SELECT 
        city,
        DATE_TRUNC('month', created_at) AS month,
        COUNT(DISTINCT booking_id) AS monthly_bookings,
        SUM(CASE WHEN status = 'confirmed' THEN price ELSE 0 END) AS monthly_revenue,
        AVG(star_rating) AS avg_star_rating
    FROM {{ source('silver', 'bookings') }}
    WHERE city IS NOT NULL
    GROUP BY city, DATE_TRUNC('month', created_at)
),

city_aggregates AS (
    SELECT 
        city,
        month AS metric_date,
        monthly_bookings AS total_bookings_month,
        monthly_revenue AS total_revenue_month,
        avg_star_rating,
        SUM(monthly_bookings) OVER (
            PARTITION BY city 
            ORDER BY month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS total_bookings_ytd,
        SUM(monthly_revenue) OVER (
            PARTITION BY city 
            ORDER BY month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS total_revenue_ytd,
        CURRENT_TIMESTAMP() AS last_updated
    FROM city_bookings
)

SELECT 
    city,
    metric_date,
    total_bookings_month,
    total_revenue_month,
    avg_star_rating,
    total_bookings_ytd,
    total_revenue_ytd,
    last_updated
FROM city_aggregates
ORDER BY city, metric_date DESC
