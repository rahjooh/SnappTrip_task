"""
Spark initialization helper for notebooks.
This module configures PySpark to work with the Dockerized Spark cluster.
"""
import os
import sys

# Add project root to path
sys.path.append('../')

# Set Java 17 as JAVA_HOME (required for PySpark 3.5.0)
os.environ['JAVA_HOME'] = '/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home'

def init_spark_session(app_name="SnappTrip-Notebook"):
    """
    Initialize a Spark session connected to the Docker Spark cluster.
    
    Args:
        app_name: Name of the Spark application
        
    Returns:
        SparkSession configured for remote cluster
    """
    from pyspark.sql import SparkSession
    
    # Configure environment for remote Spark cluster
    os.environ['SPARK_REMOTE'] = 'spark://localhost:7077'
    
    # Disable local Spark launcher to force remote connection
    os.environ['PYSPARK_SUBMIT_ARGS'] = '--master spark://localhost:7077 pyspark-shell'
    
    spark = SparkSession.builder \
        .appName(app_name) \
        .master("spark://localhost:7077") \
        .config("spark.submit.deployMode", "client") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.local.type", "hadoop") \
        .config("spark.sql.catalog.local.warehouse", "hdfs://namenode:9000/lakehouse") \
        .getOrCreate()
    
    return spark
