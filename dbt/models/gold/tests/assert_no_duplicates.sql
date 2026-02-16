-- Test: Ensure no duplicate (booking_date, city) combinations

SELECT 
    booking_date,
    city,
    COUNT(*) as duplicate_count
FROM {{ ref('gold_daily_kpis') }}
GROUP BY booking_date, city
HAVING COUNT(*) > 1
