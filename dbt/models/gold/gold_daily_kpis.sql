{{
  config(
    materialized='incremental',
    unique_key=['booking_date', 'city'],
    on_schema_change='fail',
    tags=['gold', 'kpi', 'daily']
  )
}}

/*
Gold Layer: Daily Booking KPIs by City

This model aggregates booking data from the Silver layer to provide
daily KPIs grouped by city. Metrics include booking counts, cancellation
rates, revenue, and average prices.

Grain: One row per (booking_date, city)
*/

WITH silver_bookings AS (
    SELECT 
        booking_id,
        user_id,
        hotel_id,
        status,
        price,
        created_at,
        last_updated_ts,
        processing_ts,
        city,
        star_rating
    FROM {{ source('silver', 'bookings') }}
    {% if is_incremental() %}
    -- Only process new or updated records
    WHERE processing_ts > (SELECT MAX(last_updated) FROM {{ this }})
    {% endif %}
),

daily_aggregates AS (
    SELECT 
        DATE(created_at) AS booking_date,
        city,
        COUNT(DISTINCT booking_id) AS total_bookings,
        COUNT(DISTINCT CASE WHEN status = 'confirmed' THEN booking_id END) AS confirmed_bookings,
        COUNT(DISTINCT CASE WHEN status = 'cancelled' THEN booking_id END) AS cancelled_bookings,
        COUNT(DISTINCT CASE WHEN status = 'created' THEN booking_id END) AS pending_bookings,
        
        -- Cancellation rate
        ROUND(
            COUNT(DISTINCT CASE WHEN status = 'cancelled' THEN booking_id END) * 100.0 / 
            NULLIF(COUNT(DISTINCT booking_id), 0), 
            2
        ) AS cancellation_rate,
        
        -- Revenue (only confirmed bookings)
        SUM(CASE WHEN status = 'confirmed' THEN price ELSE 0 END) AS total_revenue,
        
        -- Average prices
        AVG(price) AS avg_booking_price,
        AVG(CASE WHEN status = 'confirmed' THEN price END) AS avg_confirmed_price,
        
        -- Hotel ratings
        AVG(star_rating) AS avg_star_rating,
        
        -- Timestamps
        MAX(processing_ts) AS last_updated
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
    avg_booking_price,
    avg_confirmed_price,
    avg_star_rating,
    last_updated,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM daily_aggregates
ORDER BY booking_date DESC, city
