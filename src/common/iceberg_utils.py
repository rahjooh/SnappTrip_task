"""
Iceberg Utilities for SnappTrip Data Platform

Helper functions for working with Apache Iceberg tables.
"""

import logging
from typing import Optional
from pyspark.sql import SparkSession, DataFrame

from .config import config

logger = logging.getLogger(__name__)


def create_iceberg_table(
    spark: SparkSession,
    table_name: str,
    schema: str,
    partition_by: Optional[str] = None,
    namespace: str = "bronze"
) -> None:
    """
    Create an Iceberg table
    
    Args:
        spark: SparkSession
        table_name: Name of the table
        schema: DDL schema definition
        partition_by: Partition specification
        namespace: Iceberg namespace (bronze/silver)
    """
    full_table_name = f"local.{namespace}.{table_name}"
    
    # Create namespace if not exists
    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS local.{namespace}")
    
    # Build CREATE TABLE statement
    create_stmt = f"""
        CREATE TABLE IF NOT EXISTS {full_table_name} (
            {schema}
        ) USING iceberg
    """
    
    if partition_by:
        create_stmt += f" PARTITIONED BY ({partition_by})"
    
    create_stmt += """
        TBLPROPERTIES (
            'write.format.default' = 'parquet',
            'write.parquet.compression-codec' = 'snappy',
            'write.metadata.compression-codec' = 'gzip',
            'format-version' = '2'
        )
    """
    
    spark.sql(create_stmt)
    logger.info(f"Created Iceberg table: {full_table_name}")


def write_to_iceberg(
    df: DataFrame,
    table_name: str,
    mode: str = "append",
    namespace: str = "bronze"
) -> None:
    """
    Write DataFrame to Iceberg table
    
    Args:
        df: DataFrame to write
        table_name: Target table name
        mode: Write mode (append/overwrite)
        namespace: Iceberg namespace
    """
    full_table_name = f"local.{namespace}.{table_name}"
    
    df.writeTo(full_table_name).using("iceberg").mode(mode).save()
    
    logger.info(f"Written {df.count()} records to {full_table_name}")


def merge_into_iceberg(
    spark: SparkSession,
    source_df: DataFrame,
    target_table: str,
    merge_key: str,
    namespace: str = "silver"
) -> None:
    """
    Merge DataFrame into Iceberg table (upsert)
    
    Args:
        spark: SparkSession
        source_df: Source DataFrame
        target_table: Target table name
        merge_key: Column to merge on
        namespace: Iceberg namespace
    """
    full_table_name = f"local.{namespace}.{target_table}"
    
    # Create temporary view
    source_df.createOrReplaceTempView("source_data")
    
    # Build MERGE statement
    merge_stmt = f"""
        MERGE INTO {full_table_name} AS target
        USING source_data AS source
        ON target.{merge_key} = source.{merge_key}
        WHEN MATCHED THEN UPDATE SET *
        WHEN NOT MATCHED THEN INSERT *
    """
    
    spark.sql(merge_stmt)
    logger.info(f"Merged data into {full_table_name}")


def compact_iceberg_table(
    spark: SparkSession,
    table_name: str,
    namespace: str = "silver"
) -> None:
    """
    Compact small files in Iceberg table
    
    Args:
        spark: SparkSession
        table_name: Table name
        namespace: Iceberg namespace
    """
    full_table_name = f"local.{namespace}.{table_name}"
    
    spark.sql(f"CALL local.system.rewrite_data_files('{full_table_name}')")
    logger.info(f"Compacted table: {full_table_name}")


def expire_snapshots(
    spark: SparkSession,
    table_name: str,
    retention_days: int = 7,
    namespace: str = "silver"
) -> None:
    """
    Expire old snapshots in Iceberg table
    
    Args:
        spark: SparkSession
        table_name: Table name
        retention_days: Number of days to retain
        namespace: Iceberg namespace
    """
    full_table_name = f"local.{namespace}.{table_name}"
    
    spark.sql(f"""
        CALL local.system.expire_snapshots(
            table => '{full_table_name}',
            older_than => TIMESTAMP '{retention_days} days ago'
        )
    """)
    logger.info(f"Expired snapshots for {full_table_name}")
