-- Hotel Performance Analytics for Travel Tech Platform
-- Comprehensive hotel partner performance analysis
-- Use cases: Partner management, inventory optimization, commission strategies

WITH hotel_booking_performance AS (
    -- Core hotel booking metrics
    SELECT 
        bs.hotel_id,
        h.city,
        h.star_rating,
        
        -- === VOLUME METRICS ===
        COUNT(*) as total_bookings,
        COUNT(CASE WHEN bs.status = 'CONFIRMED' THEN 1 END) as confirmed_bookings,
        COUNT(CASE WHEN bs.status = 'CANCELLED' THEN 1 END) as cancelled_bookings,
        COUNT(CASE WHEN bs.status = 'CREATED' THEN 1 END) as pending_bookings,
        
        -- === REVENUE METRICS ===
        SUM(bs.revenue) as total_revenue,
        AVG(bs.price) as avg_booking_value,
        PERCENTILE_APPROX(bs.price, 0.5) as median_booking_value,
        MIN(CASE WHEN bs.price > 0 THEN bs.price END) as min_price,
        MAX(bs.price) as max_price,
        
        -- === CUSTOMER METRICS ===
        COUNT(DISTINCT bs.user_id) as unique_customers,
        COUNT(*) * 1.0 / COUNT(DISTINCT bs.user_id) as bookings_per_customer,
        
        -- === OPERATIONAL METRICS ===
        AVG(bs.booking_to_final_state_hours) as avg_booking_lifecycle_hours,
        AVG(bs.total_updates) as avg_booking_modifications,
        
        -- === QUALITY METRICS ===
        COUNT(CASE WHEN bs.business_risk_category != 'NORMAL' THEN 1 END) as risky_bookings,
        AVG(bs.resolution_confidence) as avg_data_quality,
        COUNT(CASE WHEN bs.same_day_cancellation = 1 THEN 1 END) as same_day_cancellations,
        SUM(bs.same_day_cancelled_value) as same_day_revenue_lost,
        
        -- === TEMPORAL PATTERNS ===
        MIN(bs.created_at) as first_booking_date,
        MAX(bs.created_at) as last_booking_date,
        DATEDIFF(MAX(bs.created_at), MIN(bs.created_at)) as booking_date_range_days,
        
        -- === BOOKING BEHAVIOR ===
        COUNT(CASE WHEN bs.instant_confirmation = 1 THEN 1 END) as instant_confirmations
        
    FROM bookings_silver bs
    INNER JOIN hotels_raw h ON bs.hotel_id = h.hotel_id
    WHERE bs.hotel_id IS NOT NULL
    GROUP BY bs.hotel_id, h.city, h.star_rating
),

hotel_performance_metrics AS (
    -- Calculate performance rates and scores
    SELECT 
        *,
        
        -- === CONVERSION RATES ===
        CASE WHEN total_bookings > 0 THEN ROUND(confirmed_bookings * 100.0 / total_bookings, 2) ELSE 0 END as confirmation_rate_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(cancelled_bookings * 100.0 / total_bookings, 2) ELSE 0 END as cancellation_rate_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(pending_bookings * 100.0 / total_bookings, 2) ELSE 0 END as pending_rate_pct,
        
        -- === EFFICIENCY RATES ===
        CASE WHEN confirmed_bookings > 0 THEN ROUND(instant_confirmations * 100.0 / confirmed_bookings, 2) ELSE 0 END as instant_confirmation_rate_pct,
        CASE WHEN total_bookings > 0 THEN ROUND(same_day_cancellations * 100.0 / total_bookings, 2) ELSE 0 END as same_day_cancellation_rate_pct,
        
        -- === REVENUE EFFICIENCY ===
        CASE WHEN confirmed_bookings > 0 THEN ROUND(total_revenue / confirmed_bookings, 2) ELSE 0 END as revenue_per_confirmed_booking,
        CASE WHEN unique_customers > 0 THEN ROUND(total_revenue / unique_customers, 2) ELSE 0 END as revenue_per_customer,
        CASE WHEN total_revenue > 0 THEN ROUND(same_day_revenue_lost * 100.0 / (total_revenue + same_day_revenue_lost), 2) ELSE 0 END as revenue_loss_pct,
        
        -- === CUSTOMER LOYALTY ===
        CASE 
            WHEN bookings_per_customer >= 3 THEN 'HIGH_LOYALTY'
            WHEN bookings_per_customer >= 1.5 THEN 'MEDIUM_LOYALTY'  
            ELSE 'LOW_LOYALTY'
        END as customer_loyalty_level,
        
        -- === BOOKING VELOCITY ===
        CASE 
            WHEN booking_date_range_days > 0 
            THEN ROUND(total_bookings * 1.0 / booking_date_range_days * 7, 1)  -- Bookings per week
            ELSE 0 
        END as bookings_per_week
        
    FROM hotel_booking_performance
),

city_benchmarks AS (
    -- Calculate city-level benchmarks for comparison
    SELECT 
        city,
        AVG(confirmation_rate_pct) as city_avg_confirmation_rate,
        AVG(cancellation_rate_pct) as city_avg_cancellation_rate,
        AVG(avg_booking_value) as city_avg_booking_value,
        AVG(instant_confirmation_rate_pct) as city_avg_instant_confirmation_rate,
        COUNT(*) as hotels_in_city
    FROM hotel_performance_metrics
    GROUP BY city
),

hotel_competitive_analysis AS (
    -- Add competitive positioning within city
    SELECT 
        hpm.*,
        cb.city_avg_confirmation_rate,
        cb.city_avg_cancellation_rate,
        cb.city_avg_booking_value,
        cb.city_avg_instant_confirmation_rate,
        cb.hotels_in_city,
        
        -- === COMPETITIVE POSITIONING ===
        CASE 
            WHEN hpm.confirmation_rate_pct > cb.city_avg_confirmation_rate * 1.1 THEN 'ABOVE_MARKET'
            WHEN hpm.confirmation_rate_pct > cb.city_avg_confirmation_rate * 0.9 THEN 'MARKET_RATE'
            ELSE 'BELOW_MARKET'
        END as confirmation_vs_market,
        
        CASE 
            WHEN hpm.cancellation_rate_pct < cb.city_avg_cancellation_rate * 0.8 THEN 'BETTER_THAN_MARKET'
            WHEN hpm.cancellation_rate_pct < cb.city_avg_cancellation_rate * 1.2 THEN 'MARKET_RATE'
            ELSE 'WORSE_THAN_MARKET'
        END as cancellation_vs_market,
        
        CASE 
            WHEN hpm.avg_booking_value > cb.city_avg_booking_value * 1.2 THEN 'PREMIUM'
            WHEN hpm.avg_booking_value > cb.city_avg_booking_value * 0.8 THEN 'MARKET_RATE'
            ELSE 'BUDGET'
        END as pricing_vs_market,
        
        -- === PERFORMANCE RANKINGS ===
        ROW_NUMBER() OVER (PARTITION BY hpm.city ORDER BY hpm.total_revenue DESC) as revenue_rank_in_city,
        ROW_NUMBER() OVER (PARTITION BY hpm.city ORDER BY hpm.confirmation_rate_pct DESC) as confirmation_rank_in_city,
        ROW_NUMBER() OVER (PARTITION BY hpm.city ORDER BY hpm.cancellation_rate_pct ASC) as cancellation_rank_in_city
        
    FROM hotel_performance_metrics hpm
    LEFT JOIN city_benchmarks cb ON hpm.city = cb.city
),

hotel_risk_opportunity_assessment AS (
    -- Identify risks and opportunities for each hotel
    SELECT 
        *,
        
        -- === PERFORMANCE CLASSIFICATION ===
        CASE 
            WHEN confirmation_rate_pct >= 80 AND cancellation_rate_pct <= 15 THEN 'HIGH_PERFORMER'
            WHEN confirmation_rate_pct >= 60 AND cancellation_rate_pct <= 25 THEN 'GOOD_PERFORMER'
            WHEN confirmation_rate_pct >= 40 AND cancellation_rate_pct <= 35 THEN 'AVERAGE_PERFORMER'
            ELSE 'POOR_PERFORMER'
        END as performance_tier,
        
        -- === BUSINESS RISK ASSESSMENT ===
        CASE 
            WHEN cancellation_rate_pct > 40 OR same_day_cancellation_rate_pct > 20 THEN 'HIGH_RISK'
            WHEN total_revenue < 1000 AND bookings_per_week < 1 THEN 'LOW_VOLUME_RISK'
            WHEN revenue_loss_pct > 15 THEN 'REVENUE_RISK'
            WHEN risky_bookings * 1.0 / total_bookings > 0.2 THEN 'OPERATIONAL_RISK'
            ELSE 'LOW_RISK'
        END as business_risk,
        
        -- === PARTNERSHIP OPPORTUNITY ===
        CASE 
            WHEN performance_tier = 'HIGH_PERFORMER' AND total_revenue > 5000 THEN 'STRATEGIC_PARTNER'
            WHEN performance_tier IN ('HIGH_PERFORMER', 'GOOD_PERFORMER') AND revenue_rank_in_city <= 3 THEN 'KEY_PARTNER'
            WHEN confirmation_vs_market = 'ABOVE_MARKET' AND bookings_per_week >= 2 THEN 'GROWTH_PARTNER'
            WHEN performance_tier = 'POOR_PERFORMER' THEN 'IMPROVEMENT_NEEDED'
            ELSE 'STANDARD_PARTNER'
        END as partnership_category,
        
        -- === RECOMMENDED ACTIONS ===
        CASE 
            WHEN business_risk = 'HIGH_RISK' THEN 'URGENT_REVIEW'
            WHEN performance_tier = 'POOR_PERFORMER' AND total_revenue > 2000 THEN 'PERFORMANCE_IMPROVEMENT_PLAN'
            WHEN partnership_category = 'STRATEGIC_PARTNER' THEN 'ENHANCE_PARTNERSHIP'
            WHEN cancellation_vs_market = 'WORSE_THAN_MARKET' THEN 'CANCELLATION_REDUCTION_FOCUS'
            WHEN pricing_vs_market = 'BUDGET' AND confirmation_rate_pct > 70 THEN 'PRICING_OPTIMIZATION'
            ELSE 'MAINTAIN_CURRENT_APPROACH'
        END as recommended_action
        
    FROM hotel_competitive_analysis
)

-- === FINAL HOTEL PERFORMANCE ANALYTICS OUTPUT ===
SELECT 
    hotel_id,
    city,
    star_rating,
    
    -- === CORE PERFORMANCE METRICS ===
    total_bookings,
    confirmed_bookings,
    cancelled_bookings,
    pending_bookings,
    
    -- === CONVERSION & EFFICIENCY ===
    confirmation_rate_pct,
    cancellation_rate_pct,
    instant_confirmation_rate_pct,
    same_day_cancellation_rate_pct,
    
    -- === REVENUE ANALYTICS ===
    total_revenue,
    avg_booking_value,
    median_booking_value,
    revenue_per_confirmed_booking,
    revenue_per_customer,
    revenue_loss_pct,
    
    -- === CUSTOMER METRICS ===
    unique_customers,
    bookings_per_customer,
    customer_loyalty_level,
    
    -- === OPERATIONAL METRICS ===
    bookings_per_week,
    avg_booking_lifecycle_hours,
    avg_booking_modifications,
    avg_data_quality,
    
    -- === COMPETITIVE POSITION ===
    confirmation_vs_market,
    cancellation_vs_market,
    pricing_vs_market,
    revenue_rank_in_city,
    confirmation_rank_in_city,
    cancellation_rank_in_city,
    
    -- === PERFORMANCE ASSESSMENT ===
    performance_tier,
    business_risk,
    partnership_category,
    recommended_action,
    
    -- === BENCHMARKS ===
    city_avg_confirmation_rate,
    city_avg_cancellation_rate,
    city_avg_booking_value,
    hotels_in_city,
    
    -- === DATE RANGE ===
    first_booking_date,
    last_booking_date,
    booking_date_range_days,
    
    -- === PROCESSING METADATA ===
    CURRENT_TIMESTAMP() as analysis_date
    
FROM hotel_risk_opportunity_assessment
ORDER BY 
    business_risk ASC,           -- Prioritize high-risk hotels
    partnership_category ASC,    -- Then by partnership importance
    total_revenue DESC,          -- Then by revenue impact
    hotel_id;