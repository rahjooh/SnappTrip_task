-- Create Gold layer database
CREATE DATABASE gold_layer;

-- Connect to gold_layer database
\c gold_layer;

-- Create Gold schema
CREATE SCHEMA IF NOT EXISTS gold;

-- Create daily_kpis table
CREATE TABLE IF NOT EXISTS gold.daily_kpis (
    booking_date DATE NOT NULL,
    city VARCHAR(100) NOT NULL,
    total_bookings INTEGER NOT NULL,
    confirmed_bookings INTEGER NOT NULL,
    cancelled_bookings INTEGER NOT NULL,
    cancellation_rate NUMERIC(5,2),
    total_revenue NUMERIC(12,2) NOT NULL,
    avg_booking_price NUMERIC(10,2),
    avg_star_rating NUMERIC(3,2),
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (booking_date, city)
);

-- Create indexes
CREATE INDEX idx_daily_kpis_date ON gold.daily_kpis(booking_date);
CREATE INDEX idx_daily_kpis_city ON gold.daily_kpis(city);

-- Create city_metrics table for additional analytics
CREATE TABLE IF NOT EXISTS gold.city_metrics (
    city VARCHAR(100) NOT NULL,
    metric_date DATE NOT NULL,
    total_hotels INTEGER,
    avg_star_rating NUMERIC(3,2),
    total_bookings_ytd INTEGER,
    total_revenue_ytd NUMERIC(15,2),
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (city, metric_date)
);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA gold TO airflow;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA gold TO airflow;
