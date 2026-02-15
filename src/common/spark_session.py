"""
Spark Session Factory for SnappTrip Data Platform

Provides configured Spark sessions with Iceberg, Kafka, and monitoring support.
"""

import logging
from typing import Optional

from pyspark.sql import SparkSession
from pyspark.conf import SparkConf

logger = logging.getLogger(__name__)


def create_spark_session(
    app_name: str,
    master: str = "spark://spark-master:7077",
    enable_hive: bool = True,
    iceberg_enabled: bool = True,
    kafka_enabled: bool = True
) -> SparkSession:
    """
    Create and configure Spark session
    
    Args:
        app_name: Name of the Spark application
        master: Spark master URL
        enable_hive: Enable Hive support
        iceberg_enabled: Enable Iceberg support
        kafka_enabled: Enable Kafka support
        
    Returns:
        Configured SparkSession
    """
    builder = SparkSession.builder.appName(app_name)
    
    if master:
        builder = builder.master(master)
    
    # Core Spark configurations
    builder = builder.config("spark.sql.adaptive.enabled", "true")
    builder = builder.config("spark.sql.adaptive.coalescePartitions.enabled", "true")
    builder = builder.config("spark.sql.adaptive.skewJoin.enabled", "true")
    
    # Serialization
    builder = builder.config("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
    
    # Arrow optimization
    builder = builder.config("spark.sql.execution.arrow.pyspark.enabled", "true")
    
    # Parquet optimization
    builder = builder.config("spark.sql.parquet.enableVectorizedReader", "true")
    builder = builder.config("spark.sql.parquet.filterPushdown", "true")
    
    # Iceberg configuration
    if iceberg_enabled:
        builder = builder.config(
            "spark.sql.extensions",
            "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
        )
        builder = builder.config(
            "spark.sql.catalog.spark_catalog",
            "org.apache.iceberg.spark.SparkSessionCatalog"
        )
        builder = builder.config("spark.sql.catalog.spark_catalog.type", "hive")
        builder = builder.config(
            "spark.sql.catalog.local",
            "org.apache.iceberg.spark.SparkCatalog"
        )
        builder = builder.config("spark.sql.catalog.local.type", "hadoop")
        builder = builder.config(
            "spark.sql.catalog.local.warehouse",
            "hdfs://namenode:9000/warehouse"
        )
    
    # Hive support
    if enable_hive:
        builder = builder.enableHiveSupport()
    
    # Create session
    spark = builder.getOrCreate()
    
    # Set log level
    spark.sparkContext.setLogLevel("WARN")
    
    logger.info(f"Spark session created: {app_name}")
    logger.info(f"Spark version: {spark.version}")
    logger.info(f"Master: {spark.sparkContext.master}")
    
    return spark


def get_or_create_spark_session(
    app_name: str,
    **kwargs
) -> SparkSession:
    """
    Get existing Spark session or create new one
    
    Args:
        app_name: Name of the Spark application
        **kwargs: Additional arguments passed to create_spark_session
        
    Returns:
        SparkSession
    """
    try:
        spark = SparkSession.getActiveSession()
        if spark:
            logger.info(f"Using existing Spark session: {spark.sparkContext.appName}")
            return spark
    except Exception:
        pass
    
    return create_spark_session(app_name, **kwargs)
