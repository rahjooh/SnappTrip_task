-- Test: Ensure total revenue is non-negative

SELECT 
    booking_date,
    city,
    total_revenue
FROM {{ ref('gold_daily_kpis') }}
WHERE total_revenue < 0
