"""
Prometheus Metrics for SnappTrip Data Platform

Provides metrics collection and reporting for pipeline monitoring.
"""

import logging
from prometheus_client import Counter, Histogram, Gauge, push_to_gateway
from typing import Optional

from .config import config

logger = logging.getLogger(__name__)

# Pipeline metrics
records_processed = Counter(
    'pipeline_records_processed_total',
    'Total records processed',
    ['layer', 'table']
)

records_rejected = Counter(
    'pipeline_records_rejected_total',
    'Total records rejected',
    ['layer', 'reason']
)

processing_duration = Histogram(
    'pipeline_processing_duration_seconds',
    'Processing duration in seconds',
    ['layer', 'job']
)

pipeline_lag = Gauge(
    'pipeline_lag_seconds',
    'Pipeline lag from source in seconds',
    ['layer']
)

data_quality_failures = Counter(
    'data_quality_failures_total',
    'Data quality check failures',
    ['layer', 'expectation']
)

# Kafka metrics
kafka_consumer_lag = Gauge(
    'kafka_consumer_lag_records',
    'Consumer lag in records',
    ['topic', 'partition']
)

kafka_messages_consumed = Counter(
    'kafka_messages_consumed_total',
    'Messages consumed from Kafka',
    ['topic']
)

# Spark metrics
spark_executor_count = Gauge(
    'spark_executor_count',
    'Number of active executors',
    ['application']
)

# Data freshness
data_last_updated_timestamp = Gauge(
    'data_last_updated_timestamp_seconds',
    'Timestamp of last data update',
    ['table']
)

# Table metrics
table_row_count = Gauge(
    'table_row_count',
    'Number of rows in table',
    ['table']
)


def push_metrics(job_name: str, registry=None):
    """
    Push metrics to Prometheus Pushgateway
    
    Args:
        job_name: Name of the job
        registry: Prometheus registry (optional)
    """
    if not config.monitoring.metrics_enabled:
        return
    
    try:
        push_to_gateway(
            config.monitoring.prometheus_pushgateway,
            job=job_name,
            registry=registry
        )
        logger.debug(f"Pushed metrics for job: {job_name}")
    except Exception as e:
        logger.warning(f"Failed to push metrics: {e}")
