{{
  config(
    materialized='table',
    tags=['gold', 'kpi', 'postgres']
  )
}}

-- This model is for PostgreSQL output
-- It reads from the Iceberg Gold layer and materializes in Postgres

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
FROM {{ ref('gold_daily_kpis_v2') }}
ORDER BY booking_date DESC, city
