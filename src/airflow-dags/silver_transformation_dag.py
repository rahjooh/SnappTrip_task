"""
Airflow DAG: Silver Layer Transformation

Orchestrates the Bronze to Silver transformation with data quality checks.
Runs every 15 minutes to process new data.
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
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=2),
    'sla': timedelta(minutes=30)
}

with DAG(
    'silver_transformation',
    default_args=default_args,
    description='Bronze to Silver transformation with data quality checks',
    schedule_interval='*/15 * * * *',  # Every 15 minutes
    start_date=days_ago(1),
    catchup=False,
    tags=['silver', 'transformation', 'critical'],
    max_active_runs=1
) as dag:

    # Spark job: Reconcile booking state
    reconcile_bookings = SparkSubmitOperator(
        task_id='reconcile_booking_state',
        application='/opt/spark/jobs/silver/booking_state_reconciliation.py',
        name='silver_booking_reconciliation',
        conf={
            'spark.sql.adaptive.enabled': 'true',
            'spark.sql.adaptive.coalescePartitions.enabled': 'true',
            'spark.sql.extensions': 'org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions',
            'spark.sql.catalog.local': 'org.apache.iceberg.spark.SparkCatalog',
            'spark.sql.catalog.local.type': 'hadoop',
            'spark.sql.catalog.local.warehouse': 'hdfs://namenode:9000/warehouse',
            'spark.executor.memory': '4g',
            'spark.executor.cores': '2',
            'spark.dynamicAllocation.enabled': 'true',
            'spark.dynamicAllocation.minExecutors': '2',
            'spark.dynamicAllocation.maxExecutors': '10'
        },
        executor_memory='4g',
        driver_memory='2g',
        num_executors=3,
        verbose=True,
        conn_id='spark_default'
    )

    def emit_metrics(**context):
        """Emit pipeline metrics to Prometheus"""
        from common.metrics import push_metrics
        push_metrics('silver_transformation')
    
    emit_pipeline_metrics = PythonOperator(
        task_id='emit_pipeline_metrics',
        python_callable=emit_metrics,
        provide_context=True
    )

    reconcile_bookings >> emit_pipeline_metrics
