{{
  config(
    materialized='incremental',
    file_format='iceberg',
    unique_key='booking_id',
    incremental_strategy='merge',
    on_schema_change='fail',
    tags=['silver', 'booking'],
    partition_by=['date(created_at)'],
    properties={
      'write.format.default': 'parquet',
      'write.parquet.compression-codec': 'snappy'
    }
  )
}}

/*
Silver Layer: Booking State with Deduplication and Enrichment

This model:
1. Deduplicates bookings from Bronze layer (takes latest by updated_at)
2. Enriches with hotel information (city, star_rating)
3. Applies business rules and data quality filters
4. Stores in Iceberg format in HDFS

Grain: One row per booking_id (deduplicated)
*/

WITH bronze_bookings AS (
    SELECT 
        booking_id,
        user_id,
        hotel_id,
        status,
        price,
        created_at,
        updated_at,
        processing_ts,
        -- Add row number for deduplication (latest record per booking_id)
        ROW_NUMBER() OVER (
            PARTITION BY booking_id 
            ORDER BY updated_at DESC, processing_ts DESC
        ) AS row_num
    FROM {{ source('bronze', 'bookings_raw') }}
    {% if is_incremental() %}
    -- Only process new or updated records
    WHERE processing_ts > (SELECT MAX(last_updated_ts) FROM {{ this }})
    {% endif %}
),

deduplicated_bookings AS (
    SELECT 
        booking_id,
        user_id,
        hotel_id,
        status,
        price,
        created_at,
        updated_at,
        processing_ts
    FROM bronze_bookings
    WHERE row_num = 1
),

hotels AS (
    SELECT 
        hotel_id,
        city,
        star_rating
    FROM {{ source('reference', 'hotels') }}
),

enriched_bookings AS (
    SELECT 
        b.booking_id,
        b.user_id,
        b.hotel_id,
        b.status,
        b.price,
        b.created_at,
        b.updated_at,
        h.city,
        h.star_rating,
        b.processing_ts AS bronze_processing_ts,
        CURRENT_TIMESTAMP() AS last_updated_ts
    FROM deduplicated_bookings b
    LEFT JOIN hotels h ON b.hotel_id = h.hotel_id
)

-- Apply business rules
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
    bronze_processing_ts,
    last_updated_ts
FROM enriched_bookings
WHERE 
    -- Business rule: price must be positive
    price > 0
    -- Business rule: status must be valid
    AND status IN ('created', 'confirmed', 'cancelled')
    -- Business rule: created_at must be before or equal to updated_at
    AND created_at <= updated_at
    -- Data quality: required fields must not be null
    AND booking_id IS NOT NULL
    AND user_id IS NOT NULL
    AND hotel_id IS NOT NULL
