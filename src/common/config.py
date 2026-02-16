"""
Configuration Management for SnappTrip Data Platform

Centralized configuration loading from environment variables and config files.
"""

import os
from dataclasses import dataclass, field
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


@dataclass
class KafkaConfig:
    """Kafka configuration"""
    bootstrap_servers: str = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka-1:9092,kafka-2:9092,kafka-3:9092")
    schema_registry_url: str = os.getenv("SCHEMA_REGISTRY_URL", "http://schema-registry:8081")
    consumer_group_id: str = os.getenv("KAFKA_CONSUMER_GROUP", "snapptrip-consumer")
    auto_offset_reset: str = "earliest"
    enable_auto_commit: bool = False
    max_poll_records: int = int(os.getenv("KAFKA_CONSUMER_MAX_POLL_RECORDS", "1000"))


@dataclass
class SparkConfig:
    """Spark configuration"""
    master: str = os.getenv("SPARK_MASTER_HOST", "spark://spark-master:7077")
    executor_memory: str = os.getenv("SPARK_EXECUTOR_MEMORY", "4g")
    driver_memory: str = os.getenv("SPARK_DRIVER_MEMORY", "2g")
    executor_cores: int = int(os.getenv("SPARK_WORKER_CORES", "2"))
    max_executors: int = int(os.getenv("MAX_EXECUTORS", "10"))
    min_executors: int = int(os.getenv("MIN_EXECUTORS", "2"))


@dataclass
class HDFSConfig:
    """HDFS configuration"""
    namenode_host: str = os.getenv("HDFS_NAMENODE_HOST", "namenode")
    namenode_port: int = int(os.getenv("HDFS_NAMENODE_PORT", "9000"))
    replication_factor: int = int(os.getenv("HDFS_REPLICATION_FACTOR", "2"))
    
    @property
    def namenode_url(self) -> str:
        return f"hdfs://{self.namenode_host}:{self.namenode_port}"


@dataclass
class IcebergConfig:
    """Iceberg configuration"""
    warehouse_path: str = "hdfs://namenode:9000/warehouse"
    catalog_type: str = "hadoop"
    
    @property
    def bronze_namespace(self) -> str:
        return "bronze"
    
    @property
    def silver_namespace(self) -> str:
        return "silver"


@dataclass
class PostgresConfig:
    """PostgreSQL configuration"""
    host: str = os.getenv("POSTGRES_HOST", "postgres")
    port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    database: str = os.getenv("GOLD_POSTGRES_DB", "gold_layer")
    user: str = os.getenv("POSTGRES_USER", "airflow")
    password: str = os.getenv("POSTGRES_PASSWORD", "airflow")
    
    @property
    def connection_url(self) -> str:
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"
    
    @property
    def jdbc_url(self) -> str:
        return f"jdbc:postgresql://{self.host}:{self.port}/{self.database}"


@dataclass
class MonitoringConfig:
    """Monitoring configuration"""
    prometheus_pushgateway: str = os.getenv("PROMETHEUS_PUSHGATEWAY", "http://prometheus:9091")
    metrics_enabled: bool = os.getenv("METRICS_ENABLED", "true").lower() == "true"
    log_level: str = os.getenv("LOG_LEVEL", "INFO")


@dataclass
class PipelineConfig:
    """Pipeline configuration"""
    watermark_delay_hours: int = int(os.getenv("WATERMARK_DELAY_HOURS", "1"))
    micro_batch_interval_minutes: int = int(os.getenv("MICRO_BATCH_INTERVAL_MINUTES", "15"))
    checkpoint_location: str = "hdfs://namenode:9000/checkpoints"
    data_retention_days: int = int(os.getenv("DATA_RETENTION_DAYS", "365"))
    environment: str = os.getenv("ENVIRONMENT", "development")


@dataclass
class Config:
    """Main configuration class"""
    kafka: KafkaConfig = field(default_factory=KafkaConfig)
    spark: SparkConfig = field(default_factory=SparkConfig)
    hdfs: HDFSConfig = field(default_factory=HDFSConfig)
    iceberg: IcebergConfig = field(default_factory=IcebergConfig)
    postgres: PostgresConfig = field(default_factory=PostgresConfig)
    monitoring: MonitoringConfig = field(default_factory=MonitoringConfig)
    pipeline: PipelineConfig = field(default_factory=PipelineConfig)


# Global configuration instance
config = Config()
