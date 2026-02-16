"""
Airflow DAG: Data Quality Checks

Runs Great Expectations validation suites on all data layers.
Executes hourly to ensure data quality standards are met.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'email': ['data-alerts@snapptrip.com'],
    'email_on_failure': True,
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    'data_quality_checks',
    default_args=default_args,
    description='Data quality validation with Great Expectations',
    schedule_interval='0 * * * *',  # Every hour
    start_date=days_ago(1),
    catchup=False,
    tags=['data-quality', 'validation', 'great-expectations']
) as dag:

    def run_ge_checkpoint(checkpoint_name, **context):
        """Run Great Expectations checkpoint"""
        import great_expectations as ge
        import logging
        
        logger = logging.getLogger(__name__)
        logger.info(f"Running Great Expectations checkpoint: {checkpoint_name}")
        
        context_root_dir = "/opt/airflow/great_expectations"
        data_context = ge.data_context.DataContext(context_root_dir)
        
        result = data_context.run_checkpoint(checkpoint_name=checkpoint_name)
        
        if not result["success"]:
            raise ValueError(f"Data quality check failed: {checkpoint_name}")
        
        logger.info(f"Checkpoint {checkpoint_name} passed successfully")
        return result

    validate_bronze = PythonOperator(
        task_id='validate_bronze_layer',
        python_callable=run_ge_checkpoint,
        op_kwargs={'checkpoint_name': 'bronze_checkpoint'},
        provide_context=True
    )

    validate_silver = PythonOperator(
        task_id='validate_silver_layer',
        python_callable=run_ge_checkpoint,
        op_kwargs={'checkpoint_name': 'silver_checkpoint'},
        provide_context=True
    )

    validate_gold = PythonOperator(
        task_id='validate_gold_layer',
        python_callable=run_ge_checkpoint,
        op_kwargs={'checkpoint_name': 'gold_checkpoint'},
        provide_context=True
    )

    validate_bronze >> validate_silver >> validate_gold
