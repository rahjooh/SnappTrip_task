#!/usr/bin/env python3
"""
Transfer Gold layer data from Iceberg to PostgreSQL

This script reads the gold_daily_kpis_v2 table from Iceberg (via Spark)
and writes it to PostgreSQL for external consumption.
"""

import os
import sys
from pyspark.sql import SparkSession
import psycopg2
import pandas as pd
from sqlalchemy import create_engine, text
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_spark_session():
    """Create Spark session with Iceberg support"""
    
    # Get warehouse path from environment or use default
    warehouse = os.getenv('LAKEHOUSE_WAREHOUSE', 'file:///tmp/lakehouse')
    
    spark = SparkSession.builder \
        .appName("IcebergToPostgreSQL") \
        .config("spark.jars.packages", 
                "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.3,"
                "org.apache.hadoop:hadoop-client:3.3.6,"
                "org.postgresql:postgresql:42.7.2") \
        .config("spark.sql.extensions", 
                "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.local", 
                "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.local.type", "hadoop") \
        .config("spark.sql.catalog.local.warehouse", warehouse) \
        .config("spark.sql.defaultCatalog", "local") \
        .getOrCreate()
    
    return spark

def get_postgres_connection_string():
    """Get PostgreSQL connection string from environment or defaults"""
    
    host = os.getenv('POSTGRES_HOST', 'postgres')
    port = os.getenv('POSTGRES_PORT', '5432')
    database = os.getenv('POSTGRES_DB', 'gold_layer')
    user = os.getenv('POSTGRES_USER', 'airflow')
    password = os.getenv('POSTGRES_PASSWORD', 'airflow')
    
    return f"postgresql://{user}:{password}@{host}:{port}/{database}"

def transfer_gold_data():
    """Main transfer function"""
    
    logger.info("Starting Iceberg to PostgreSQL transfer...")
    
    # Create Spark session
    spark = create_spark_session()
    
    try:
        # Read from Iceberg
        logger.info("Reading gold_daily_kpis_v2 from Iceberg...")
        iceberg_df = spark.sql("SELECT * FROM local.gold.gold_daily_kpis_v2")
        
        # Convert to Pandas for easier PostgreSQL write
        logger.info("Converting to Pandas DataFrame...")
        pandas_df = iceberg_df.toPandas()
        
        logger.info(f"Retrieved {len(pandas_df)} records from Iceberg")
        
        # Write to PostgreSQL
        logger.info("Writing to PostgreSQL...")
        conn_str = get_postgres_connection_string()
        engine = create_engine(conn_str)
        
        # Write to PostgreSQL table
        pandas_df.to_sql(
            'gold_daily_kpis_postgres',
            engine,
            schema='gold',
            if_exists='replace',
            index=False,
            method='multi'
        )
        
        logger.info(f"Successfully transferred {len(pandas_df)} records to PostgreSQL")
        
        # Verify write
        with engine.connect() as conn:
            result = conn.execute(text("SELECT COUNT(*) FROM gold.gold_daily_kpis_postgres"))
            count = result.scalar()
            logger.info(f"PostgreSQL table now contains {count} records")
        
    except Exception as e:
        logger.error(f"Transfer failed: {str(e)}")
        raise e
    
    finally:
        spark.stop()
        logger.info("Transfer completed")

if __name__ == "__main__":
    transfer_gold_data()