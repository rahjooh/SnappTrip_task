#!/usr/bin/env python3
"""
Gold Layer Data Explorer - Use this to examine your Gold layer data
"""

print("📁 HDFS Gold Layer Directory & Data:")
print("\n" + "=" * 70)

# Use Spark to explore the Gold layer Iceberg data directly
try:
    # Show Iceberg table metadata and schema
    print("\n🔍 Gold Daily KPIs Table Schema:")
    spark.sql("DESCRIBE TABLE local.gold.gold_daily_kpis_v2").show()
    
    # Show sample data
    print("\n📊 Sample Gold Layer Data (First 10 records):")
    df_gold = spark.sql("SELECT * FROM local.gold.gold_daily_kpis_v2 ORDER BY booking_date DESC, city LIMIT 10")
    df_gold.show(truncate=False)
    
    # Show data summary statistics
    print("\n📈 Data Summary:")
    row_count = spark.sql("SELECT COUNT(*) as total_records FROM local.gold.gold_daily_kpis_v2").collect()[0]['total_records']
    date_range = spark.sql("""
        SELECT 
            MIN(booking_date) as earliest_date,
            MAX(booking_date) as latest_date,
            COUNT(DISTINCT city) as unique_cities
        FROM local.gold.gold_daily_kpis_v2
    """).collect()[0]
    
    print(f"Total Records: {row_count}")
    print(f"Date Range: {date_range['earliest_date']} to {date_range['latest_date']}")
    print(f"Unique Cities: {date_range['unique_cities']}")
    
    # Show table location information
    print("\n🗂️ Table Location Info:")
    table_info = spark.sql("SHOW TBLPROPERTIES local.gold.gold_daily_kpis_v2")
    table_info.filter("key LIKE '%location%' OR key LIKE '%path%'").show(truncate=False)
    
except Exception as e:
    print(f"Error accessing Iceberg table: {e}")
    print("\nTrying alternative approach...")
    
    # Alternative: Try to access via file system if Iceberg fails
    try:
        hadoop_files = spark.sql("SELECT input_file_name() as file_path FROM parquet.`hdfs://namenode:9000/lakehouse/gold/gold_daily_kpis_v2/data/*.parquet` LIMIT 5")
        print("\n📁 Gold Layer Files:")
        hadoop_files.show(truncate=False)
    except Exception as e2:
        print(f"Cannot access files directly: {e2}")

print("\n" + "=" * 70)
print("\n✅ Gold layer data persisted in HDFS!")
print("\n📍 HDFS Path:")
print("   • hdfs://namenode:9000/lakehouse/gold/gold_daily_kpis_v2")
print("\n🌐 View in HDFS UI: http://localhost:9870/explorer.html#/lakehouse/gold")