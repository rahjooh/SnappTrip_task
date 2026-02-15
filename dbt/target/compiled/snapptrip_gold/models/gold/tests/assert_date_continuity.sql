-- Test: Check for missing dates in the time series

WITH date_series AS (
    SELECT 
        DATE_ADD(DATE('2025-01-01'), seq) AS expected_date
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS seq
        FROM gold.gold_daily_kpis
        LIMIT 365
    )
),

actual_dates AS (
    SELECT DISTINCT booking_date
    FROM gold.gold_daily_kpis
)

SELECT 
    expected_date
FROM date_series
WHERE expected_date NOT IN (SELECT booking_date FROM actual_dates)
  AND expected_date <= CURRENT_DATE()