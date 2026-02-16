"""
Bronze Layer - Raw data ingestion from Kafka to Iceberg.
"""

from .kafka_to_iceberg import BronzeIngestion as BronzeLayer

__all__ = ['BronzeLayer']
