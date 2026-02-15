"""
Airflow DAG: Gold Layer Aggregation

Runs dbt models to aggregate Silver data into Gold layer KPIs.
Executes every 30 minutes after Silver layer completes.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'email': ['data-alerts@snapptrip.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=1)
}

with DAG(
    'gold_aggregation',
    default_args=default_args,
    description='Silver to Gold aggregation using dbt',
    schedule_interval='*/30 * * * *',  # Every 30 minutes
    start_date=days_ago(1),
    catchup=False,
    tags=['gold', 'aggregation', 'dbt'],
    max_active_runs=1
) as dag:

    # Run dbt models
    dbt_run = BashOperator(
        task_id='dbt_run_gold_models',
        bash_command='cd /opt/airflow/dbt && dbt run --models gold.*',
        env={
            'DBT_PROFILES_DIR': '/opt/airflow/dbt',
            'DBT_TARGET': 'prod'
        }
    )

    # Run dbt tests
    dbt_test = BashOperator(
        task_id='dbt_test_gold_models',
        bash_command='cd /opt/airflow/dbt && dbt test --models gold.*',
        env={
            'DBT_PROFILES_DIR': '/opt/airflow/dbt',
            'DBT_TARGET': 'prod'
        }
    )

    # Generate dbt docs
    dbt_docs = BashOperator(
        task_id='dbt_generate_docs',
        bash_command='cd /opt/airflow/dbt && dbt docs generate',
        env={
            'DBT_PROFILES_DIR': '/opt/airflow/dbt',
            'DBT_TARGET': 'prod'
        }
    )

    def emit_metrics(**context):
        """Emit pipeline metrics"""
        from common.metrics import push_metrics
        push_metrics('gold_aggregation')
    
    emit_pipeline_metrics = PythonOperator(
        task_id='emit_pipeline_metrics',
        python_callable=emit_metrics,
        provide_context=True
    )

    dbt_run >> dbt_test >> dbt_docs >> emit_pipeline_metrics
