#!/usr/bin/env python3
"""
SnappTrip Data Pipeline - Bronze → Silver → Gold
Local execution using Spark SQL on plain files

This script demonstrates the complete data pipeline execution
without requiring external infrastructure.
"""

from pyspark.sql import SparkSession
import os
from pathlib import Path


def create_spark_session():
    """Create Spark session for local execution"""
    return SparkSession.builder \
        .appName("SnappTrip-DataPipeline") \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .getOrCreate()

def load_bronze_tables(spark, base_path):
    """Load raw CSV files as Spark DataFrames and create temporary views"""
    
    print("📊 Loading Bronze layer (raw data)...")
    
    # Load bookings_raw (supports both ISO 'T' and space in timestamps)
    bookings_raw_path = f"{base_path}/data/bronze/bookings_raw.csv"
    bookings_raw_df = spark.read.csv(bookings_raw_path, header=True, inferSchema=True, timestampFormat="yyyy-MM-dd'T'HH:mm:ss")
    bookings_raw_df.createOrReplaceTempView("bookings_raw")
    print(f"   ✓ Loaded bookings_raw: {bookings_raw_df.count()} records")
    
    # Load booking_events_raw (supports ISO 'T' in timestamps)
    events_raw_path = f"{base_path}/data/bronze/booking_events_raw.csv"
    events_raw_df = spark.read.csv(events_raw_path, header=True, inferSchema=True, timestampFormat="yyyy-MM-dd'T'HH:mm:ss")
    events_raw_df.createOrReplaceTempView("booking_events_raw")
    print(f"   ✓ Loaded booking_events_raw: {events_raw_df.count()} records")
    
    # Load hotels_raw
    hotels_raw_path = f"{base_path}/data/bronze/hotels_raw.csv"
    hotels_raw_df = spark.read.csv(hotels_raw_path, header=True, inferSchema=True)
    hotels_raw_df.createOrReplaceTempView("hotels_raw")
    print(f"   ✓ Loaded hotels_raw: {hotels_raw_df.count()} records")
    
    return bookings_raw_df, events_raw_df, hotels_raw_df

def execute_sql_file(spark, sql_file_path):
    """Execute SQL file and return resulting DataFrame"""
    with open(sql_file_path, 'r') as file:
        sql_content = file.read()
    
    return spark.sql(sql_content)

def run_silver_layer(spark, base_path):
    """Execute Silver layer transformation"""
    
    print("\n🥈 Executing Silver layer transformation...")
    
    sql_file = f"{base_path}/sql/silver/bookings_silver.sql"
    silver_df = execute_sql_file(spark, sql_file)
    
    # Create temporary view for Gold layer
    silver_df.createOrReplaceTempView("bookings_silver")
    
    print(f"   ✓ Silver layer complete: {silver_df.count()} bookings processed")
    
    # Show sample results
    print("\n   📋 Sample Silver layer results:")
    silver_df.select("booking_id", "status", "price", "final_state_ts", "is_confirmed", "revenue").show(10)
    
    return silver_df

def run_gold_layer(spark, base_path):
    """Execute Gold layer transformation"""
    
    print("\n🥇 Executing Gold layer transformations...")
    
    # Execute main daily KPIs
    print("\n   📊 Processing Daily Booking KPIs...")
    daily_kpis_file = f"{base_path}/sql/gold/daily_booking_kpis.sql"
    daily_kpis_df = execute_sql_file(spark, daily_kpis_file)
    daily_kpis_df.createOrReplaceTempView("daily_booking_kpis")
    print(f"   ✓ Daily KPIs complete: {daily_kpis_df.count()} daily city records")
    
    # Execute customer behavior analytics
    print("\n   👥 Processing Customer Behavior Analytics...")
    customer_analytics_file = f"{base_path}/sql/gold/customer_behavior_analytics.sql"
    customer_df = execute_sql_file(spark, customer_analytics_file)
    customer_df.createOrReplaceTempView("customer_behavior_analytics")
    print(f"   ✓ Customer analytics complete: {customer_df.count()} customer profiles")
    
    # Execute hotel performance analytics
    print("\n   🏨 Processing Hotel Performance Analytics...")
    hotel_analytics_file = f"{base_path}/sql/gold/hotel_performance_analytics.sql"
    hotel_df = execute_sql_file(spark, hotel_analytics_file)
    hotel_df.createOrReplaceTempView("hotel_performance_analytics")
    print(f"   ✓ Hotel analytics complete: {hotel_df.count()} hotel profiles")
    
    # Show sample results from each analytics layer
    print("\n   📈 Sample Daily KPIs:")
    daily_kpis_df.select(
        "booking_date", 
        "city", 
        "total_bookings", 
        "confirmed_bookings", 
        "confirmation_rate_pct",
        "total_revenue",
        "daily_alert_status"
    ).show(10)
    
    print("\n   👤 Sample Customer Segments:")
    customer_df.select(
        "user_id",
        "total_bookings",
        "total_customer_revenue",
        "customer_tier",
        "churn_risk",
        "recommended_action"
    ).show(10)
    
    print("\n   🏨 Sample Hotel Performance:")
    hotel_df.select(
        "hotel_id",
        "city",
        "total_bookings",
        "confirmation_rate_pct",
        "total_revenue",
        "performance_tier",
        "partnership_category"
    ).show(10)
    
    return daily_kpis_df, customer_df, hotel_df

def save_results(silver_df, daily_kpis_df, customer_df, hotel_df, base_path):
    """Save results to output directory"""
    
    print("\n💾 Saving results...")
    
    output_path = f"{base_path}/output"
    
    # Save Silver layer
    silver_df.coalesce(1).write.mode("overwrite").csv(f"{output_path}/silver/bookings_silver", header=True)
    print(f"   ✓ Silver layer saved to {output_path}/silver/")
    
    # Save Gold layer analytics
    daily_kpis_df.coalesce(1).write.mode("overwrite").csv(f"{output_path}/gold/daily_booking_kpis", header=True)
    print(f"   ✓ Daily KPIs saved to {output_path}/gold/daily_booking_kpis/")
    
    customer_df.coalesce(1).write.mode("overwrite").csv(f"{output_path}/gold/customer_behavior_analytics", header=True)
    print(f"   ✓ Customer analytics saved to {output_path}/gold/customer_behavior_analytics/")
    
    hotel_df.coalesce(1).write.mode("overwrite").csv(f"{output_path}/gold/hotel_performance_analytics", header=True)
    print(f"   ✓ Hotel analytics saved to {output_path}/gold/hotel_performance_analytics/")

def show_data_quality_metrics(spark):
    """Display comprehensive data quality and business insights"""
    
    print("\n🔍 Data Quality & Business Intelligence Summary:")
    
    # Silver layer data quality
    print("\n   📊 Silver Layer Quality Metrics:")
    spark.sql("""
        SELECT 
            COUNT(*) as total_processed_bookings,
            COUNT(DISTINCT booking_id) as unique_bookings,
            COUNT(*) - COUNT(DISTINCT booking_id) as duplicate_bookings,
            AVG(resolution_confidence) as avg_resolution_confidence,
            COUNT(CASE WHEN data_quality_risk = 'HIGH' THEN 1 END) as high_risk_bookings,
            COUNT(CASE WHEN business_risk_category != 'NORMAL' THEN 1 END) as business_risk_bookings
        FROM bookings_silver
    """).show()
    
    # Status and resolution methods
    print("\n   📈 Booking Status & Resolution Distribution:")
    spark.sql("""
        SELECT 
            status,
            resolution_method,
            COUNT(*) as count, 
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
        FROM bookings_silver 
        GROUP BY status, resolution_method
        ORDER BY count DESC
    """).show()
    
    # Business performance summary
    print("\n   💼 Business Performance Summary:")
    spark.sql("""
        SELECT 
            city,
            COUNT(DISTINCT booking_date) as active_days,
            SUM(total_revenue) as total_city_revenue,
            SUM(confirmed_bookings) as total_confirmed_bookings,
            AVG(confirmation_rate_pct) as avg_confirmation_rate,
            COUNT(CASE WHEN daily_alert_status != 'NORMAL' THEN 1 END) as alert_days
        FROM daily_booking_kpis 
        GROUP BY city 
        ORDER BY total_city_revenue DESC
    """).show()
    
    # Customer insights
    print("\n   👥 Customer Insights:")
    spark.sql("""
        SELECT 
            customer_tier,
            churn_risk,
            COUNT(*) as customer_count,
            SUM(total_customer_revenue) as segment_revenue,
            AVG(estimated_annual_clv) as avg_estimated_clv
        FROM customer_behavior_analytics
        GROUP BY customer_tier, churn_risk
        ORDER BY segment_revenue DESC
    """).show()
    
    # Hotel partnership insights  
    print("\n   🏨 Hotel Partnership Overview:")
    spark.sql("""
        SELECT 
            performance_tier,
            partnership_category,
            COUNT(*) as hotel_count,
            SUM(total_revenue) as tier_revenue,
            AVG(confirmation_rate_pct) as avg_confirmation_rate
        FROM hotel_performance_analytics
        GROUP BY performance_tier, partnership_category
        ORDER BY tier_revenue DESC
    """).show()

def main():
    """Main pipeline execution"""
    
    # Get base path
    base_path = Path(__file__).parent.absolute()
    
    print("🚀 Starting SnappTrip Data Pipeline")
    print(f"📁 Working directory: {base_path}")
    
    # Initialize Spark
    spark = create_spark_session()
    
    try:
        # Load Bronze layer
        load_bronze_tables(spark, base_path)
        
        # Execute Silver layer
        silver_df = run_silver_layer(spark, base_path)
        
        # Execute Gold layer
        daily_kpis_df, customer_df, hotel_df = run_gold_layer(spark, base_path)
        
        # Save results
        save_results(silver_df, daily_kpis_df, customer_df, hotel_df, base_path)
        
        # Show data quality metrics
        show_data_quality_metrics(spark)
        
        print("\n✅ Pipeline execution completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Pipeline failed: {str(e)}")
        raise
    finally:
        spark.stop()

if __name__ == "__main__":
    main()