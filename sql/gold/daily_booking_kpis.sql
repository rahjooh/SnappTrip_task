-- Gold Layer: Advanced Travel Industry KPIs and Analytics
-- Comprehensive travel tech analytics with industry best practices
-- Features: Revenue optimization, customer behavior, operational efficiency, risk management

WITH silver_enriched AS (
    -- Step 1: Enrich silver data with hotel context and derived metrics
    SELECT 
        bs.*,
        h.city,
        h.star_rating,
        DATE(bs.created_at) as booking_date,
        DATE(bs.final_state_ts) as final_status_date,
        
        -- Travel industry specific calculations
        EXTRACT(hour FROM bs.created_at) as booking_hour,
        EXTRACT(dow FROM bs.created_at) as booking_day_of_week, -- 0=Sunday, 6=Saturday
        
        -- Lead time analysis (assuming check-in date is booking date + 7 days for demo)
        7 as assumed_lead_time_days,
        
        -- Customer value segmentation
        CASE 
            WHEN bs.price >= 1000 THEN 'PREMIUM'
            WHEN bs.price >= 500 THEN 'HIGH_VALUE'
            WHEN bs.price >= 200 THEN 'STANDARD'
            ELSE 'BUDGET'
        END as customer_segment,
        
        -- Booking behavior flags
        CASE 
            WHEN EXTRACT(hour FROM bs.created_at) BETWEEN 9 AND 17 THEN 'BUSINESS_HOURS'
            WHEN EXTRACT(hour FROM bs.created_at) BETWEEN 18 AND 22 THEN 'EVENING'
            ELSE 'OFF_HOURS'
        END as booking_time_segment,
        
        CASE 
            WHEN EXTRACT(dow FROM bs.created_at) IN (0, 6) THEN 'WEEKEND'
            ELSE 'WEEKDAY'
        END as booking_day_type
        
    FROM bookings_silver bs
    INNER JOIN hotels_raw h ON bs.hotel_id = h.hotel_id
    WHERE bs.booking_id IS NOT NULL -- Filter invalid records
),

comprehensive_daily_metrics AS (
    -- Step 2: Calculate comprehensive daily metrics by city
    SELECT 
        booking_date,
        city,
        
        -- === CORE VOLUME METRICS ===
        COUNT(*) as total_bookings,
        SUM(is_confirmed) as confirmed_bookings,
        SUM(is_cancelled) as cancelled_bookings,
        SUM(is_pending) as pending_bookings,
        
        -- === REVENUE METRICS ===
        SUM(revenue) as total_revenue,
        SUM(same_day_cancelled_value) as same_day_cancelled_revenue_lost,
        SUM(CASE WHEN is_confirmed = 1 THEN price ELSE 0 END) as confirmed_revenue_check,
        
        -- Revenue by customer segment
        SUM(CASE WHEN customer_segment = 'PREMIUM' AND is_confirmed = 1 THEN price ELSE 0 END) as premium_revenue,
        SUM(CASE WHEN customer_segment = 'HIGH_VALUE' AND is_confirmed = 1 THEN price ELSE 0 END) as high_value_revenue,
        SUM(CASE WHEN customer_segment = 'STANDARD' AND is_confirmed = 1 THEN price ELSE 0 END) as standard_revenue,
        SUM(CASE WHEN customer_segment = 'BUDGET' AND is_confirmed = 1 THEN price ELSE 0 END) as budget_revenue,
        
        -- === CUSTOMER BEHAVIOR METRICS ===
        -- Booking time patterns
        COUNT(CASE WHEN booking_time_segment = 'BUSINESS_HOURS' THEN 1 END) as business_hours_bookings,
        COUNT(CASE WHEN booking_time_segment = 'EVENING' THEN 1 END) as evening_bookings,
        COUNT(CASE WHEN booking_time_segment = 'OFF_HOURS' THEN 1 END) as off_hours_bookings,
        
        -- Weekend vs weekday patterns
        COUNT(CASE WHEN booking_day_type = 'WEEKEND' THEN 1 END) as weekend_bookings,
        COUNT(CASE WHEN booking_day_type = 'WEEKDAY' THEN 1 END) as weekday_bookings,
        
        -- Customer segment distribution
        COUNT(CASE WHEN customer_segment = 'PREMIUM' THEN 1 END) as premium_bookings,
        COUNT(CASE WHEN customer_segment = 'HIGH_VALUE' THEN 1 END) as high_value_bookings,
        COUNT(CASE WHEN customer_segment = 'STANDARD' THEN 1 END) as standard_bookings,
        COUNT(CASE WHEN customer_segment = 'BUDGET' THEN 1 END) as budget_bookings,
        
        -- === OPERATIONAL EFFICIENCY METRICS ===
        -- Decision speed analysis
        COUNT(CASE WHEN booking_decision_speed = 'IMMEDIATE' THEN 1 END) as immediate_decisions,
        COUNT(CASE WHEN booking_decision_speed = 'SAME_DAY' THEN 1 END) as same_day_decisions,
        COUNT(CASE WHEN booking_decision_speed = 'SAME_WEEK' THEN 1 END) as same_week_decisions,
        COUNT(CASE WHEN booking_decision_speed = 'DELAYED' THEN 1 END) as delayed_decisions,
        
        -- Instant confirmations (high efficiency indicator)
        SUM(instant_confirmation) as instant_confirmations,
        SUM(same_day_cancellation) as same_day_cancellations,
        
        -- === QUALITY & RISK METRICS ===
        -- Data quality indicators
        COUNT(CASE WHEN data_quality_risk = 'HIGH' THEN 1 END) as high_risk_bookings,
        COUNT(CASE WHEN data_quality_risk = 'MEDIUM' THEN 1 END) as medium_risk_bookings,
        COUNT(CASE WHEN data_quality_risk = 'LOW' THEN 1 END) as low_risk_bookings,
        
        -- Business risk categories
        COUNT(CASE WHEN business_risk_category = 'HIGH_VALUE_CANCELLATION' THEN 1 END) as high_value_cancellations,
        COUNT(CASE WHEN business_risk_category = 'HIGH_TOUCH_BOOKING' THEN 1 END) as high_touch_bookings,
        COUNT(CASE WHEN business_risk_category = 'STALE_PENDING' THEN 1 END) as stale_pending_bookings,
        
        -- === PRICING & VALUE METRICS ===
        AVG(price) as avg_booking_value,
        AVG(CASE WHEN is_confirmed = 1 THEN price END) as avg_confirmed_booking_value,
        PERCENTILE_APPROX(price, 0.5) as median_booking_value,
        PERCENTILE_APPROX(price, 0.9) as p90_booking_value,
        
        -- Hotel quality metrics
        AVG(star_rating) as avg_hotel_rating,
        
        -- === PROCESS EFFICIENCY METRICS ===
        AVG(booking_to_final_state_hours) as avg_booking_lifecycle_hours,
        AVG(total_updates) as avg_updates_per_booking,
        AVG(resolution_confidence) as avg_resolution_confidence
        
    FROM silver_enriched
    GROUP BY booking_date, city
),

calculated_kpis AS (
    -- Step 3: Calculate derived KPIs and rates
    SELECT 
        *,
        
        -- === CONVERSION & RETENTION RATES ===
        CASE WHEN total_bookings > 0 THEN ROUND(confirmed_bookings * 100.0 / total_bookings, 2) ELSE 0 END as confirmation_rate_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(cancelled_bookings * 100.0 / total_bookings, 2) ELSE 0 END as cancellation_rate_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(pending_bookings * 100.0 / total_bookings, 2) ELSE 0 END as pending_rate_pct,
        
        -- Same-day performance indicators
        CASE WHEN total_bookings > 0 THEN ROUND(same_day_cancellations * 100.0 / total_bookings, 2) ELSE 0 END as same_day_cancellation_rate_pct,
        CASE WHEN confirmed_bookings > 0 THEN ROUND(instant_confirmations * 100.0 / confirmed_bookings, 2) ELSE 0 END as instant_confirmation_rate_pct,
        
        -- === REVENUE EFFICIENCY ===
        CASE WHEN confirmed_bookings > 0 THEN ROUND(total_revenue / confirmed_bookings, 2) ELSE 0 END as revenue_per_confirmed_booking,
        CASE WHEN total_bookings > 0 THEN ROUND(total_revenue / total_bookings, 2) ELSE 0 END as revenue_per_total_booking,
        CASE WHEN total_revenue > 0 THEN ROUND(same_day_cancelled_revenue_lost * 100.0 / (total_revenue + same_day_cancelled_revenue_lost), 2) ELSE 0 END as same_day_revenue_loss_pct,
        
        -- Customer segment performance
        CASE WHEN total_bookings > 0 THEN ROUND(premium_bookings * 100.0 / total_bookings, 2) ELSE 0 END as premium_segment_pct,
        CASE WHEN total_revenue > 0 THEN ROUND(premium_revenue * 100.0 / total_revenue, 2) ELSE 0 END as premium_revenue_contribution_pct,
        
        -- === OPERATIONAL EFFICIENCY ===
        CASE WHEN total_bookings > 0 THEN ROUND(business_hours_bookings * 100.0 / total_bookings, 2) ELSE 0 END as business_hours_booking_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(weekend_bookings * 100.0 / total_bookings, 2) ELSE 0 END as weekend_booking_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(immediate_decisions * 100.0 / total_bookings, 2) ELSE 0 END as immediate_decision_rate_pct,
        
        -- === QUALITY SCORES ===
        CASE WHEN total_bookings > 0 THEN ROUND(low_risk_bookings * 100.0 / total_bookings, 2) ELSE 0 END as data_quality_score_pct,
        CASE WHEN total_bookings > 0 THEN ROUND((high_value_cancellations + high_touch_bookings + stale_pending_bookings) * 100.0 / total_bookings, 2) ELSE 0 END as business_risk_score_pct
        
    FROM comprehensive_daily_metrics
),

travel_industry_benchmarks AS (
    -- Step 4: Add travel industry benchmarks and alerts
    SELECT 
        *,
        
        -- === PERFORMANCE BENCHMARKS ===
        -- Industry benchmarks (typical ranges for hotel bookings)
        CASE 
            WHEN confirmation_rate_pct >= 80 THEN 'EXCELLENT'
            WHEN confirmation_rate_pct >= 65 THEN 'GOOD'
            WHEN confirmation_rate_pct >= 50 THEN 'AVERAGE'
            ELSE 'POOR'
        END as confirmation_performance,
        
        CASE 
            WHEN cancellation_rate_pct <= 10 THEN 'EXCELLENT'
            WHEN cancellation_rate_pct <= 20 THEN 'GOOD'
            WHEN cancellation_rate_pct <= 35 THEN 'AVERAGE'
            ELSE 'POOR'
        END as cancellation_performance,
        
        CASE 
            WHEN instant_confirmation_rate_pct >= 60 THEN 'EXCELLENT'
            WHEN instant_confirmation_rate_pct >= 40 THEN 'GOOD'
            WHEN instant_confirmation_rate_pct >= 25 THEN 'AVERAGE'
            ELSE 'POOR'
        END as response_speed_performance,
        
        -- === BUSINESS ALERTS ===
        CASE 
            WHEN cancellation_rate_pct > 40 THEN 'HIGH_CANCELLATION_ALERT'
            WHEN same_day_revenue_loss_pct > 15 THEN 'REVENUE_LOSS_ALERT'
            WHEN business_risk_score_pct > 20 THEN 'OPERATIONAL_RISK_ALERT'
            WHEN data_quality_score_pct < 80 THEN 'DATA_QUALITY_ALERT'
            WHEN total_bookings = 0 THEN 'NO_BOOKINGS_ALERT'
            ELSE 'NORMAL'
        END as daily_alert_status,
        
        -- === COMPETITIVE POSITIONING ===
        -- Compare to city average (simplified)
        CASE 
            WHEN revenue_per_confirmed_booking > avg_confirmed_booking_value * 1.2 THEN 'PREMIUM_POSITIONING'
            WHEN revenue_per_confirmed_booking > avg_confirmed_booking_value * 0.8 THEN 'MARKET_RATE'
            ELSE 'BUDGET_POSITIONING'
        END as pricing_positioning
        
    FROM calculated_kpis
)

-- === FINAL GOLD LAYER OUTPUT ===
SELECT 
    booking_date,
    city,
    
    -- === CORE METRICS ===
    total_bookings,
    confirmed_bookings,
    cancelled_bookings,
    pending_bookings,
    
    -- === KEY PERFORMANCE RATES ===
    confirmation_rate_pct,
    cancellation_rate_pct,
    pending_rate_pct,
    same_day_cancellation_rate_pct,
    instant_confirmation_rate_pct,
    
    -- === REVENUE METRICS ===
    total_revenue,
    revenue_per_confirmed_booking,
    revenue_per_total_booking,
    same_day_cancelled_revenue_lost,
    same_day_revenue_loss_pct,
    
    -- === CUSTOMER SEGMENTATION ===
    premium_bookings,
    high_value_bookings,
    standard_bookings,
    budget_bookings,
    premium_segment_pct,
    premium_revenue_contribution_pct,
    
    -- === OPERATIONAL METRICS ===
    business_hours_booking_pct,
    weekend_booking_pct,
    immediate_decision_rate_pct,
    avg_booking_lifecycle_hours,
    avg_updates_per_booking,
    
    -- === QUALITY & RISK ===
    data_quality_score_pct,
    business_risk_score_pct,
    high_risk_bookings,
    avg_resolution_confidence,
    
    -- === PRICING ANALYTICS ===
    avg_booking_value,
    avg_confirmed_booking_value,
    median_booking_value,
    p90_booking_value,
    avg_hotel_rating,
    
    -- === PERFORMANCE ASSESSMENT ===
    confirmation_performance,
    cancellation_performance,
    response_speed_performance,
    pricing_positioning,
    daily_alert_status,
    
    -- === DETAILED BREAKDOWNS ===
    -- Time-based patterns
    business_hours_bookings,
    evening_bookings,
    off_hours_bookings,
    weekend_bookings,
    weekday_bookings,
    
    -- Decision speed patterns
    immediate_decisions,
    same_day_decisions,
    same_week_decisions,
    delayed_decisions,
    
    -- Revenue by segment
    premium_revenue,
    high_value_revenue,
    standard_revenue,
    budget_revenue,
    
    -- Risk indicators
    high_value_cancellations,
    high_touch_bookings,
    stale_pending_bookings,
    
    -- === METADATA ===
    CURRENT_TIMESTAMP() as processed_at,
    'ENHANCED_TRAVEL_ANALYTICS_V2' as model_version
    
FROM travel_industry_benchmarks
ORDER BY 
    booking_date DESC, 
    daily_alert_status ASC,  -- Prioritize alerts
    total_revenue DESC,      -- Then by revenue impact
    city ASC;