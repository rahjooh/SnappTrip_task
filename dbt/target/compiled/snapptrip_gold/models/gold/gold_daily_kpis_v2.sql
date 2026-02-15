

/*
Gold Layer: Daily Booking KPIs by City

This model aggregates Silver layer booking data to provide
daily KPIs grouped by city. Stores in Iceberg format in HDFS.

Grain: One row per (booking_date, city) combination
*/

WITH silver_bookings AS (
    SELECT 
        booking_id,
        user_id,
        hotel_id,
        status,
        price,
        created_at,
        updated_at,
        city,
        star_rating,
        last_updated_ts
    FROM silver.silver_booking_state
    
    -- Only process new or updated records
    WHERE last_updated_ts > (SELECT MAX(last_updated) FROM gold.gold_daily_kpis_v2)
    
),

daily_aggregates AS (
    SELECT 
        DATE(created_at) AS booking_date,
        city,
        
        -- Booking counts
        COUNT(DISTINCT booking_id) AS total_bookings,
        COUNT(DISTINCT CASE WHEN status = 'confirmed' THEN booking_id END) AS confirmed_bookings,
        COUNT(DISTINCT CASE WHEN status = 'cancelled' THEN booking_id END) AS cancelled_bookings,
        COUNT(DISTINCT CASE WHEN status = 'created' THEN booking_id END) AS pending_bookings,
        
        -- Cancellation rate (%)
        ROUND(
            CAST(COUNT(DISTINCT CASE WHEN status = 'cancelled' THEN booking_id END) AS DOUBLE) * 100.0 / 
            NULLIF(COUNT(DISTINCT booking_id), 0), 
            2
        ) AS cancellation_rate,
        
        -- Revenue metrics (only confirmed bookings generate revenue)
        SUM(CASE WHEN status = 'confirmed' THEN price ELSE 0 END) AS total_revenue,
        ROUND(AVG(CASE WHEN status = 'confirmed' THEN price END), 2) AS avg_confirmed_price,
        
        -- Price metrics (all bookings)
        ROUND(AVG(price), 2) AS avg_booking_price,
        MIN(price) AS min_price,
        MAX(price) AS max_price,
        
        -- Hotel quality metrics
        ROUND(AVG(star_rating), 2) AS avg_star_rating,
        
        -- Unique customers
        COUNT(DISTINCT user_id) AS unique_customers,
        
        -- Timestamps
        MAX(last_updated_ts) AS last_updated,
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM silver_bookings
    WHERE city IS NOT NULL
    GROUP BY DATE(created_at), city
)

SELECT 
    booking_date,
    city,
    total_bookings,
    confirmed_bookings,
    cancelled_bookings,
    pending_bookings,
    cancellation_rate,
    total_revenue,
    avg_confirmed_price,
    avg_booking_price,
    min_price,
    max_price,
    avg_star_rating,
    unique_customers,
    last_updated,
    dbt_updated_at
FROM daily_aggregates
ORDER BY booking_date DESC, city