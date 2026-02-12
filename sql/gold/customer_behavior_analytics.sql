-- Customer Behavior Analytics for Travel Tech
-- Advanced customer segmentation and behavior analysis
-- Use cases: Personalization, retention strategies, lifetime value optimization

WITH customer_booking_patterns AS (
    -- Analyze individual customer booking behavior
    SELECT 
        user_id,
        COUNT(*) as total_bookings,
        COUNT(CASE WHEN status = 'CONFIRMED' THEN 1 END) as confirmed_bookings,
        COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_bookings,
        
        -- Revenue metrics per customer
        SUM(revenue) as total_customer_revenue,
        AVG(price) as avg_booking_value,
        MAX(price) as max_booking_value,
        MIN(CASE WHEN price > 0 THEN price END) as min_booking_value,
        
        -- Temporal patterns
        MIN(created_at) as first_booking_date,
        MAX(created_at) as last_booking_date,
        DATEDIFF(MAX(created_at), MIN(created_at)) as customer_lifespan_days,
        
        -- Booking frequency
        CASE 
            WHEN DATEDIFF(MAX(created_at), MIN(created_at)) > 0 
            THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(MAX(created_at), MIN(created_at)) * 30
            ELSE 0 
        END as bookings_per_month,
        
        -- Decision-making behavior
        AVG(booking_to_final_state_hours) as avg_decision_time_hours,
        AVG(total_updates) as avg_booking_modifications,
        
        -- Hotel preferences
        COUNT(DISTINCT hotel_id) as unique_hotels_booked,
        -- Most booked hotel (simplified - gets first hotel alphabetically)
        MIN(hotel_id) as preferred_hotel_id,
        
        -- Quality indicators
        AVG(resolution_confidence) as avg_data_quality,
        COUNT(CASE WHEN business_risk_category != 'NORMAL' THEN 1 END) as risky_bookings
        
    FROM bookings_silver
    WHERE user_id IS NOT NULL AND user_id != ''
    GROUP BY user_id
),

customer_segmentation AS (
    -- Create comprehensive customer segments
    SELECT 
        *,
        
        -- RFM-style segmentation adapted for travel
        CASE 
            WHEN DATEDIFF(CURRENT_TIMESTAMP(), last_booking_date) <= 30 THEN 'RECENT'
            WHEN DATEDIFF(CURRENT_TIMESTAMP(), last_booking_date) <= 90 THEN 'ACTIVE'
            WHEN DATEDIFF(CURRENT_TIMESTAMP(), last_booking_date) <= 365 THEN 'DORMANT'
            ELSE 'INACTIVE'
        END as recency_segment,
        
        CASE 
            WHEN bookings_per_month >= 2 THEN 'FREQUENT'
            WHEN bookings_per_month >= 0.5 THEN 'REGULAR'
            WHEN bookings_per_month >= 0.1 THEN 'OCCASIONAL'
            ELSE 'RARE'
        END as frequency_segment,
        
        CASE 
            WHEN total_customer_revenue >= 2000 THEN 'HIGH_VALUE'
            WHEN total_customer_revenue >= 500 THEN 'MEDIUM_VALUE'
            WHEN total_customer_revenue >= 100 THEN 'LOW_VALUE'
            ELSE 'MINIMAL_VALUE'
        END as monetary_segment,
        
        -- Behavioral segments
        CASE 
            WHEN confirmed_bookings * 1.0 / total_bookings >= 0.8 THEN 'DECISIVE'
            WHEN confirmed_bookings * 1.0 / total_bookings >= 0.5 THEN 'MODERATE'
            ELSE 'HESITANT'
        END as decision_behavior,
        
        CASE 
            WHEN avg_decision_time_hours <= 1 THEN 'INSTANT'
            WHEN avg_decision_time_hours <= 24 THEN 'QUICK'
            WHEN avg_decision_time_hours <= 168 THEN 'SLOW'
            ELSE 'VERY_SLOW'
        END as decision_speed,
        
        CASE 
            WHEN unique_hotels_booked = 1 THEN 'LOYAL'
            WHEN unique_hotels_booked <= 3 THEN 'SOMEWHAT_LOYAL'
            ELSE 'EXPLORER'
        END as hotel_loyalty
        
    FROM customer_booking_patterns
),

customer_risk_analysis AS (
    -- Identify at-risk customers and opportunities
    SELECT 
        *,
        
        -- Churn risk indicators
        CASE 
            WHEN recency_segment = 'INACTIVE' AND frequency_segment IN ('FREQUENT', 'REGULAR') THEN 'HIGH_CHURN_RISK'
            WHEN recency_segment = 'DORMANT' AND monetary_segment IN ('HIGH_VALUE', 'MEDIUM_VALUE') THEN 'MEDIUM_CHURN_RISK'
            WHEN cancelled_bookings * 1.0 / total_bookings > 0.5 THEN 'HIGH_CANCELLATION_RISK'
            ELSE 'LOW_RISK'
        END as churn_risk,
        
        -- Growth opportunity
        CASE 
            WHEN recency_segment = 'RECENT' AND frequency_segment = 'RARE' AND decision_behavior = 'DECISIVE' THEN 'GROWTH_OPPORTUNITY'
            WHEN monetary_segment = 'LOW_VALUE' AND frequency_segment IN ('FREQUENT', 'REGULAR') THEN 'UPSELL_OPPORTUNITY'
            WHEN hotel_loyalty = 'LOYAL' AND total_customer_revenue >= 500 THEN 'VIP_POTENTIAL'
            ELSE 'MAINTAIN'
        END as growth_opportunity,
        
        -- Customer lifetime value estimation (simplified)
        CASE 
            WHEN bookings_per_month > 0 
            THEN ROUND(avg_booking_value * bookings_per_month * 12 * 
                      (confirmed_bookings * 1.0 / total_bookings), 2)
            ELSE 0 
        END as estimated_annual_clv
        
    FROM customer_segmentation
)

-- Final customer analytics output
SELECT 
    user_id,
    
    -- === CORE METRICS ===
    total_bookings,
    confirmed_bookings,
    cancelled_bookings,
    total_customer_revenue,
    avg_booking_value,
    
    -- === BEHAVIORAL PATTERNS ===
    customer_lifespan_days,
    bookings_per_month,
    avg_decision_time_hours,
    avg_booking_modifications,
    unique_hotels_booked,
    
    -- === SEGMENTATION ===
    recency_segment,
    frequency_segment,
    monetary_segment,
    decision_behavior,
    decision_speed,
    hotel_loyalty,
    
    -- === RISK & OPPORTUNITY ===
    churn_risk,
    growth_opportunity,
    estimated_annual_clv,
    
    -- === QUALITY INDICATORS ===
    avg_data_quality,
    risky_bookings,
    
    -- === DATES ===
    first_booking_date,
    last_booking_date,
    
    -- === BUSINESS INSIGHTS ===
    CASE 
        WHEN recency_segment = 'RECENT' AND frequency_segment IN ('FREQUENT', 'REGULAR') 
             AND monetary_segment IN ('HIGH_VALUE', 'MEDIUM_VALUE') THEN 'VIP_CUSTOMER'
        WHEN churn_risk = 'HIGH_CHURN_RISK' THEN 'AT_RISK_CUSTOMER'
        WHEN growth_opportunity = 'GROWTH_OPPORTUNITY' THEN 'PROMISING_CUSTOMER'
        WHEN total_bookings = 1 AND confirmed_bookings = 1 THEN 'NEW_CUSTOMER'
        ELSE 'STANDARD_CUSTOMER'
    END as customer_tier,
    
    -- === RECOMMENDED ACTIONS ===
    CASE 
        WHEN churn_risk = 'HIGH_CHURN_RISK' THEN 'RETENTION_CAMPAIGN'
        WHEN growth_opportunity = 'UPSELL_OPPORTUNITY' THEN 'UPSELL_CAMPAIGN'
        WHEN growth_opportunity = 'VIP_POTENTIAL' THEN 'VIP_INVITATION'
        WHEN recency_segment = 'RECENT' AND total_bookings = 1 THEN 'WELCOME_SERIES'
        WHEN recency_segment = 'DORMANT' THEN 'REACTIVATION_CAMPAIGN'
        ELSE 'NURTURE_CAMPAIGN'
    END as recommended_action,
    
    CURRENT_TIMESTAMP() as analysis_date
    
FROM customer_risk_analysis
ORDER BY 
    churn_risk ASC,
    estimated_annual_clv DESC,
    total_customer_revenue DESC;