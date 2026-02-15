
  
    
        create or replace table gold.gold_daily_kpis_postgres
      
      
    using iceberg
      
      
      
      
      
      

      as
      

-- This model validates and exposes the transferred PostgreSQL data
-- The actual data transfer is handled by the Python transfer script

-- Note: This table is populated by the transfer_to_postgres.py script
-- which reads from Iceberg gold_daily_kpis_v2 and writes to PostgreSQL

-- Create empty table with correct structure - will be populated by Python script
SELECT 
    CAST(NULL AS DATE) as booking_date,
    CAST(NULL AS VARCHAR(255)) as city,
    CAST(NULL AS BIGINT) as total_bookings,
    CAST(NULL AS BIGINT) as confirmed_bookings,
    CAST(NULL AS BIGINT) as cancelled_bookings,
    CAST(NULL AS BIGINT) as pending_bookings,
    CAST(NULL AS DECIMAL(5,2)) as cancellation_rate,
    CAST(NULL AS DECIMAL(15,2)) as total_revenue,
    CAST(NULL AS DECIMAL(10,2)) as avg_confirmed_price,
    CAST(NULL AS DECIMAL(10,2)) as avg_booking_price,
    CAST(NULL AS DECIMAL(10,2)) as min_price,
    CAST(NULL AS DECIMAL(10,2)) as max_price,
    CAST(NULL AS DECIMAL(3,2)) as avg_star_rating,
    CAST(NULL AS BIGINT) as unique_customers,
    CAST(NULL AS TIMESTAMP) as last_updated,
    CAST(NULL AS TIMESTAMP) as dbt_updated_at,
    CURRENT_TIMESTAMP as postgres_updated_at
WHERE FALSE  -- This ensures no rows are inserted, just creates the table structure
  