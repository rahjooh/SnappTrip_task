"""
Gold Layer - Daily KPIs calculation.

This module calculates daily booking KPIs by city and writes to PostgreSQL.
"""

import logging
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import (
    col, count, sum as spark_sum, round as spark_round,
    date_trunc, when, countDistinct
)
from typing import Optional

logger = logging.getLogger(__name__)


class GoldLayer:
    """Gold layer for calculating daily KPIs."""
    
    def __init__(self, spark: Optional[SparkSession] = None):
        """
        Initialize Gold layer.
        
        Args:
            spark: SparkSession (creates new if None)
        """
        self.spark = spark or self._create_spark_session()
        logger.info("Gold layer initialized")
    
    @staticmethod
    def _create_spark_session() -> SparkSession:
        """Create Spark session with required configurations."""
        return SparkSession.builder \
            .appName("GoldLayer-DailyKPIs") \
            .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkSessionCatalog") \
            .config("spark.sql.catalog.spark_catalog.type", "hive") \
            .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.local.type", "hadoop") \
            .config("spark.sql.catalog.local.warehouse", "hdfs://namenode:9000/lakehouse") \
            .getOrCreate()
    
    def calculate_daily_kpis(self, silver_table: str = "local.silver.booking_state") -> DataFrame:
        """
        Calculate daily KPIs from silver layer.
        
        Args:
            silver_table: Silver Iceberg table name
            
        Returns:
            DataFrame with daily KPIs
        """
        logger.info(f"Calculating daily KPIs from {silver_table}")
        
        # Read from silver layer
        silver_df = self.spark.table(silver_table)
        
        # Calculate daily KPIs by city
        kpis_df = silver_df.groupBy(
            date_trunc("day", col("created_at")).alias("booking_date"),
            col("city")
        ).agg(
            countDistinct("booking_id").alias("total_bookings"),
            spark_sum(when(col("status") == "confirmed", 1).otherwise(0)).alias("confirmed_bookings"),
            spark_sum(when(col("status") == "cancelled", 1).otherwise(0)).alias("cancelled_bookings"),
            spark_sum(when(col("status") == "confirmed", col("price")).otherwise(0)).alias("total_revenue"),
            spark_round(
                (spark_sum(when(col("status") == "cancelled", 1).otherwise(0)) * 100.0) / 
                countDistinct("booking_id"), 
                2
            ).alias("cancellation_rate"),
            spark_round(
                spark_sum(col("price")) / countDistinct("booking_id"),
                2
            ).alias("avg_booking_price")
        ).orderBy("booking_date", "city")
        
        logger.info(f"Calculated KPIs for {kpis_df.count()} date-city combinations")
        return kpis_df
    
    def write_to_postgres(self, kpis_df: DataFrame, 
                         table: str = "gold_daily_kpis",
                         jdbc_url: str = "jdbc:postgresql://postgres:5432/snapptrip_analytics",
                         properties: Optional[dict] = None):
        """
        Write KPIs to PostgreSQL.
        
        Args:
            kpis_df: DataFrame with KPIs
            table: PostgreSQL table name
            jdbc_url: JDBC connection URL
            properties: JDBC connection properties
        """
        if properties is None:
            properties = {
                "user": "snapptrip",
                "password": "snapptrip123",
                "driver": "org.postgresql.Driver"
            }
        
        logger.info(f"Writing {kpis_df.count()} rows to PostgreSQL table: {table}")
        
        kpis_df.write \
            .format("jdbc") \
            .option("url", jdbc_url) \
            .option("dbtable", table) \
            .option("mode", "overwrite") \
            .options(**properties) \
            .save()
        
        logger.info(f"Successfully wrote KPIs to {table}")
    
    def run(self, silver_table: str = "local.silver.booking_state",
            postgres_table: str = "gold_daily_kpis"):
        """
        Run the complete Gold layer pipeline.
        
        Args:
            silver_table: Silver Iceberg table name
            postgres_table: PostgreSQL table name
        """
        logger.info("Starting Gold layer pipeline")
        
        # Calculate KPIs
        kpis_df = self.calculate_daily_kpis(silver_table)
        
        # Write to PostgreSQL
        self.write_to_postgres(kpis_df, postgres_table)
        
        logger.info("Gold layer pipeline completed successfully")


def calculate_daily_kpis(silver_table: str = "local.silver.booking_state",
                        postgres_table: str = "gold_daily_kpis"):
    """
    Calculate daily KPIs and write to PostgreSQL.
    
    Args:
        silver_table: Silver Iceberg table name
        postgres_table: PostgreSQL table name
    """
    gold = GoldLayer()
    gold.run(silver_table, postgres_table)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    calculate_daily_kpis()
