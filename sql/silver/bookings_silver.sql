-- Silver Layer: Latest Booking State with Comprehensive Business Logic
-- Implements travel industry best practices and handles all edge cases
-- Features: Data quality validation, business rules, audit trails, anomaly detection

WITH data_quality_validation AS (
    -- Step 1: Validate and clean raw booking data
    SELECT 
        booking_id,
        user_id,
        hotel_id,
        UPPER(TRIM(status)) as status,
        price,
        created_at,
        updated_at,
        -- Data quality flags
        CASE WHEN booking_id IS NULL OR booking_id = '' THEN 1 ELSE 0 END as missing_booking_id,
        CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END as missing_user_id,
        CASE WHEN hotel_id IS NULL OR hotel_id = '' THEN 1 ELSE 0 END as missing_hotel_id,
        CASE WHEN price IS NULL OR price < 0 THEN 1 ELSE 0 END as invalid_price,
        CASE WHEN price > 50000 THEN 1 ELSE 0 END as suspicious_high_price, -- Flagg prices > $50k
        CASE WHEN created_at IS NULL THEN 1 ELSE 0 END as missing_created_at,
        CASE WHEN updated_at IS NULL THEN 1 ELSE 0 END as missing_updated_at,
        CASE WHEN updated_at < created_at THEN 1 ELSE 0 END as invalid_timestamp_order,
        CASE WHEN UPPER(TRIM(status)) NOT IN ('CREATED', 'CONFIRMED', 'CANCELLED') THEN 1 ELSE 0 END as invalid_status,
        -- Travel industry specific validations
        CASE WHEN created_at > CURRENT_TIMESTAMP() THEN 1 ELSE 0 END as future_booking_creation,
        CASE WHEN DATEDIFF(CURRENT_TIMESTAMP(), created_at) > 730 THEN 1 ELSE 0 END as very_old_booking, -- > 2 years
        -- Calculate booking lead time and lifecycle duration
        DATEDIFF(hour, created_at, updated_at) as booking_lifecycle_hours
    FROM bookings_raw
    WHERE booking_id IS NOT NULL AND booking_id != '' -- Filter out completely invalid records
),

event_quality_validation AS (
    -- Step 2: Validate and clean event data
    SELECT 
        booking_id,
        UPPER(TRIM(event_type)) as event_type,
        event_ts,
        -- Event quality flags
        CASE WHEN booking_id IS NULL OR booking_id = '' THEN 1 ELSE 0 END as missing_booking_id,
        CASE WHEN event_ts IS NULL THEN 1 ELSE 0 END as missing_event_ts,
        CASE WHEN UPPER(TRIM(event_type)) NOT IN ('CREATED', 'CONFIRMED', 'CANCELLED') THEN 1 ELSE 0 END as invalid_event_type,
        CASE WHEN event_ts > CURRENT_TIMESTAMP() THEN 1 ELSE 0 END as future_event,
        -- Calculate event lateness (events arriving after typical business hours)
        CASE WHEN DATEDIFF(hour, event_ts, CURRENT_TIMESTAMP()) > 72 THEN 1 ELSE 0 END as late_arriving_event
    FROM booking_events_raw
    WHERE booking_id IS NOT NULL AND booking_id != ''
),

booking_state_transitions AS (
    -- Step 3: Analyze booking state transitions for validation
    SELECT 
        booking_id,
        status,
        created_at,
        updated_at,
        price,
        user_id,
        hotel_id,
        -- Track booking state history and transitions
        LAG(status) OVER (PARTITION BY booking_id ORDER BY updated_at) as previous_status,
        LAG(updated_at) OVER (PARTITION BY booking_id ORDER BY updated_at) as previous_updated_at,
        ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY updated_at DESC) as recency_rank,
        COUNT(*) OVER (PARTITION BY booking_id) as total_updates,
        -- Validate state transitions (business rules)
        CASE 
            WHEN LAG(status) OVER (PARTITION BY booking_id ORDER BY updated_at) = 'CANCELLED' 
                 AND status != 'CANCELLED' THEN 1 
            ELSE 0 
        END as invalid_transition_from_cancelled,
        -- Calculate time between status changes
        COALESCE(
            DATEDIFF(hour, 
                LAG(updated_at) OVER (PARTITION BY booking_id ORDER BY updated_at), 
                updated_at
            ), 
            0
        ) as hours_since_last_update
    FROM data_quality_validation
    WHERE missing_booking_id = 0 AND invalid_timestamp_order = 0 -- Only process valid records
),

event_state_transitions AS (
    -- Step 4: Analyze event state transitions
    SELECT 
        booking_id,
        event_type,
        event_ts,
        LAG(event_type) OVER (PARTITION BY booking_id ORDER BY event_ts) as previous_event_type,
        ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY event_ts DESC) as event_recency_rank,
        COUNT(*) OVER (PARTITION BY booking_id) as total_events,
        -- Detect duplicate events within short time windows
        CASE 
            WHEN LAG(event_type) OVER (PARTITION BY booking_id ORDER BY event_ts) = event_type
                 AND DATEDIFF(minute, 
                     LAG(event_ts) OVER (PARTITION BY booking_id ORDER BY event_ts), 
                     event_ts) <= 5 THEN 1
            ELSE 0
        END as potential_duplicate_event
    FROM event_quality_validation
    WHERE missing_booking_id = 0 AND missing_event_ts = 0
),

latest_valid_bookings AS (
    -- Step 5: Get latest valid booking state per booking_id
    SELECT 
        booking_id,
        user_id,
        hotel_id,
        status as bookings_status,
        price,
        created_at,
        updated_at,
        total_updates,
        hours_since_last_update,
        invalid_transition_from_cancelled,
        -- Data quality summary
        CASE WHEN total_updates > 10 THEN 1 ELSE 0 END as high_update_frequency,
        CASE WHEN hours_since_last_update > 168 THEN 1 ELSE 0 END as stale_booking -- > 1 week
    FROM booking_state_transitions
    WHERE recency_rank = 1 -- Latest state only
),

latest_valid_events AS (
    -- Step 6: Get latest valid event per booking_id
    SELECT 
        booking_id,
        event_type as events_status,
        event_ts,
        total_events,
        potential_duplicate_event
    FROM event_state_transitions
    WHERE event_recency_rank = 1 -- Latest event only
),

comprehensive_booking_analysis AS (
    -- Step 7: Combine bookings and events with advanced conflict resolution
    SELECT 
        b.booking_id,
        b.user_id,
        b.hotel_id,
        b.bookings_status,
        b.price,
        b.created_at,
        b.updated_at,
        e.events_status,
        e.event_ts,
        b.total_updates,
        e.total_events,
        b.hours_since_last_update,
        b.invalid_transition_from_cancelled,
        b.high_update_frequency,
        b.stale_booking,
        e.potential_duplicate_event,
        
        -- Advanced conflict resolution logic
        CASE 
            -- Rule 1: If booking has invalid transition, trust events if available
            WHEN b.invalid_transition_from_cancelled = 1 AND e.events_status IS NOT NULL THEN e.events_status
            -- Rule 2: If event is more recent by significant margin (>30 mins), trust event
            WHEN e.event_ts IS NOT NULL AND e.event_ts > b.updated_at + INTERVAL 30 MINUTES THEN e.events_status
            -- Rule 3: If booking is very recent (< 5 mins) compared to event, trust booking
            WHEN e.event_ts IS NOT NULL AND b.updated_at > e.event_ts + INTERVAL 5 MINUTES THEN b.bookings_status
            -- Rule 4: For potential duplicate events, prefer booking status
            WHEN e.potential_duplicate_event = 1 THEN b.bookings_status
            -- Rule 5: Default timestamp-based resolution
            WHEN e.event_ts IS NULL THEN b.bookings_status
            WHEN e.event_ts > b.updated_at THEN e.events_status
            ELSE b.bookings_status 
        END as resolved_status,
        
        -- Determine authoritative timestamp
        CASE 
            WHEN b.invalid_transition_from_cancelled = 1 AND e.events_status IS NOT NULL THEN e.event_ts
            WHEN e.event_ts IS NOT NULL AND e.event_ts > b.updated_at + INTERVAL 30 MINUTES THEN e.event_ts
            WHEN e.event_ts IS NOT NULL AND b.updated_at > e.event_ts + INTERVAL 5 MINUTES THEN b.updated_at
            WHEN e.potential_duplicate_event = 1 THEN b.updated_at
            WHEN e.event_ts IS NULL THEN b.updated_at
            WHEN e.event_ts > b.updated_at THEN e.event_ts
            ELSE b.updated_at 
        END as authoritative_timestamp,
        
        -- Confidence scoring for resolution
        CASE 
            WHEN b.invalid_transition_from_cancelled = 1 THEN 0.6  -- Low confidence due to invalid transition
            WHEN e.potential_duplicate_event = 1 THEN 0.7         -- Medium-low due to duplicate
            WHEN b.high_update_frequency = 1 THEN 0.8             -- Medium due to high frequency
            WHEN ABS(DATEDIFF(minute, COALESCE(e.event_ts, b.updated_at), b.updated_at)) <= 5 THEN 0.95  -- High confidence for close timestamps
            ELSE 0.9  -- Default high confidence
        END as resolution_confidence
    FROM latest_valid_bookings b
    LEFT JOIN latest_valid_events e ON b.booking_id = e.booking_id
),

travel_business_metrics AS (
    -- Step 8: Calculate travel industry specific metrics
    SELECT 
        *,
        -- Booking behavior analysis
        DATEDIFF(hour, created_at, authoritative_timestamp) as booking_to_final_state_hours,
        CASE 
            WHEN DATEDIFF(hour, created_at, authoritative_timestamp) <= 1 THEN 'IMMEDIATE'
            WHEN DATEDIFF(hour, created_at, authoritative_timestamp) <= 24 THEN 'SAME_DAY'
            WHEN DATEDIFF(hour, created_at, authoritative_timestamp) <= 168 THEN 'SAME_WEEK'
            ELSE 'DELAYED'
        END as booking_decision_speed,
        
        -- Revenue and pricing analysis
        CASE 
            WHEN resolved_status = 'CONFIRMED' THEN price 
            ELSE 0 
        END as confirmed_revenue,
        
        CASE 
            WHEN resolved_status = 'CANCELLED' AND DATEDIFF(hour, created_at, authoritative_timestamp) <= 24 THEN price
            ELSE 0 
        END as same_day_cancelled_value,
        
        -- Risk scoring
        CASE 
            WHEN resolution_confidence < 0.7 THEN 'HIGH'
            WHEN resolution_confidence < 0.9 THEN 'MEDIUM'
            ELSE 'LOW'
        END as data_quality_risk,
        
        CASE 
            WHEN price > 1000 AND resolved_status = 'CANCELLED' THEN 'HIGH_VALUE_CANCELLATION'
            WHEN total_updates > 5 THEN 'HIGH_TOUCH_BOOKING'
            WHEN DATEDIFF(hour, created_at, CURRENT_TIMESTAMP()) > 168 AND resolved_status = 'CREATED' THEN 'STALE_PENDING'
            ELSE 'NORMAL'
        END as business_risk_category
    FROM comprehensive_booking_analysis
)

-- Final Silver Layer Output with Complete Business Context
SELECT 
    booking_id,
    user_id,
    hotel_id,
    resolved_status as status,
    price,
    created_at,
    updated_at,
    event_ts,
    authoritative_timestamp as final_state_ts,
    
    -- Core business flags
    CASE WHEN resolved_status = 'CONFIRMED' THEN 1 ELSE 0 END as is_confirmed,
    CASE WHEN resolved_status = 'CANCELLED' THEN 1 ELSE 0 END as is_cancelled,
    CASE WHEN resolved_status = 'CREATED' THEN 1 ELSE 0 END as is_pending,
    
    -- Revenue calculations
    confirmed_revenue as revenue,
    same_day_cancelled_value,
    
    -- Operational metrics
    total_updates,
    total_events,
    booking_to_final_state_hours,
    booking_decision_speed,
    
    -- Quality and risk indicators
    resolution_confidence,
    data_quality_risk,
    business_risk_category,
    
    -- Data quality flags
    invalid_transition_from_cancelled,
    high_update_frequency,
    stale_booking,
    potential_duplicate_event,
    
    -- Audit trail
    CASE 
        WHEN event_ts IS NOT NULL AND event_ts != updated_at THEN 'EVENT_OVERRIDE'
        WHEN invalid_transition_from_cancelled = 1 THEN 'INVALID_TRANSITION_CORRECTED'
        WHEN potential_duplicate_event = 1 THEN 'DUPLICATE_EVENT_HANDLED'
        ELSE 'STANDARD_RESOLUTION'
    END as resolution_method,
    
    -- Processing metadata
    CURRENT_TIMESTAMP() as processed_at,
    
    -- Travel industry KPIs
    CASE 
        WHEN resolved_status = 'CONFIRMED' AND booking_decision_speed = 'IMMEDIATE' THEN 1 
        ELSE 0 
    END as instant_confirmation,
    
    CASE 
        WHEN resolved_status = 'CANCELLED' AND DATEDIFF(hour, created_at, authoritative_timestamp) <= 24 THEN 1 
        ELSE 0 
    END as same_day_cancellation
    
FROM travel_business_metrics
WHERE booking_id IS NOT NULL  -- Final validation
ORDER BY 
    data_quality_risk DESC,  -- Prioritize risky bookings for review
    resolution_confidence ASC,
    booking_id;