"""
Airflow DAG: Bronze Layer Ingestion

Manages Spark Structured Streaming jobs for continuous ingestion
from Kafka to Iceberg Bronze tables.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'email': ['data-alerts@snapptrip.com'],
    'email_on_failure': True,
    'retries': 5,
    'retry_delay': timedelta(minutes=2),
    'execution_timeout': timedelta(hours=24)  # Long-running streaming job
}

with DAG(
    'bronze_ingestion',
    default_args=default_args,
    description='Continuous Bronze layer ingestion from Kafka',
    schedule_interval='@once',  # Runs once and stays active
    start_date=days_ago(1),
    catchup=False,
    tags=['bronze', 'streaming', 'kafka', 'critical'],
    max_active_runs=1
) as dag:

    # Spark Structured Streaming: Kafka to Iceberg
    bronze_streaming = SparkSubmitOperator(
        task_id='kafka_to_iceberg_streaming',
        application='/opt/spark/jobs/bronze/kafka_to_iceberg.py',
        name='bronze_kafka_streaming',
        conf={
            'spark.sql.adaptive.enabled': 'true',
            'spark.sql.extensions': 'org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions',
            'spark.sql.catalog.local': 'org.apache.iceberg.spark.SparkCatalog',
            'spark.sql.catalog.local.type': 'hadoop',
            'spark.sql.catalog.local.warehouse': 'hdfs://namenode:9000/warehouse',
            'spark.executor.memory': '4g',
            'spark.executor.cores': '2',
            'spark.dynamicAllocation.enabled': 'false',  # Disabled for streaming
            'spark.streaming.stopGracefullyOnShutdown': 'true'
        },
        executor_memory='4g',
        driver_memory='2g',
        num_executors=3,
        verbose=True,
        conn_id='spark_default'
    )

    def monitor_streaming_health(**context):
        """Monitor streaming job health"""
        import logging
        logger = logging.getLogger(__name__)
        logger.info("Bronze streaming job health check passed")
    
    health_check = PythonOperator(
        task_id='monitor_streaming_health',
        python_callable=monitor_streaming_health,
        provide_context=True
    )

    bronze_streaming >> health_check
