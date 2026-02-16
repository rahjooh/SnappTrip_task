# System Overview - SnappTrip Data Platform

## Introduction

The SnappTrip Data Platform is an enterprise-grade lakehouse architecture designed to handle booking data for a 20M customer travel-tech startup. The platform implements a medallion architecture (Bronze → Silver → Gold) with real-time streaming, comprehensive monitoring, and ML integration.

## Architecture Principles

1. **Scalability**: Horizontal scaling through distributed processing (Spark, Kafka)
2. **Reliability**: Multi-layer validation, data quality checks, and fault tolerance
3. **Performance**: Optimized query execution with AQE, partitioning, and caching
4. **Observability**: Comprehensive monitoring with Prometheus, Grafana, and Loki
5. **Maintainability**: Modular design with clear separation of concerns

## Technology Stack

### Data Storage
- **HDFS**: Distributed file system for Bronze/Silver layers
- **Apache Iceberg**: Table format with ACID transactions and time-travel
- **PostgreSQL**: Relational database for Gold layer and metadata

### Data Processing
- **Apache Spark**: Distributed processing engine for ETL
- **PySpark**: Python API for Spark with custom transformations
- **dbt**: SQL-based transformations for analytics

### Streaming & Messaging
- **Apache Kafka**: Distributed event streaming platform
- **Schema Registry**: Centralized schema management with Avro
- **Spark Structured Streaming**: Micro-batch processing

### Orchestration
- **Apache Airflow**: Workflow orchestration with DAGs
- **Celery**: Distributed task queue for Airflow

### Query Engine
- **Trino**: Distributed SQL query engine for ad-hoc analytics

### Monitoring & Observability
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Tempo**: Distributed tracing
- **Alertmanager**: Alert routing and notification

### Data Quality
- **Great Expectations**: Data validation and profiling
- **dbt tests**: SQL-based data quality tests

### ML Platform
- **Kubeflow**: ML pipeline orchestration
- **Feast**: Feature store for ML
- **MLflow**: Experiment tracking and model registry

## Data Flow

```
CDC Sources → Kafka Topics (with Schema Registry)
    ↓
Bronze Layer (Iceberg on HDFS) - Raw data ingestion
    ↓
Silver Layer (Iceberg on HDFS) - Cleaned & reconciled data
    ↓
Gold Layer (PostgreSQL) - Aggregated KPIs & metrics
    ↓
Analytics & ML (Trino, Kubeflow, Feast)
```

## Layer Responsibilities

### Bronze Layer
- **Purpose**: Raw data ingestion from Kafka
- **Format**: Iceberg tables on HDFS
- **Processing**: Spark Structured Streaming
- **Validation**: Schema validation, null checks
- **Frequency**: Real-time (30-second micro-batches)

### Silver Layer
- **Purpose**: Data cleaning, reconciliation, and enrichment
- **Format**: Iceberg tables on HDFS
- **Processing**: PySpark batch jobs
- **Validation**: Great Expectations suites
- **Frequency**: Every 15 minutes

### Gold Layer
- **Purpose**: Business metrics and KPIs
- **Format**: PostgreSQL tables
- **Processing**: dbt models
- **Validation**: dbt tests
- **Frequency**: Every 30 minutes

## Key Features

### 1. State Reconciliation
- Reconciles booking state from multiple sources
- Handles late-arriving events with watermarking
- Deduplication and conflict resolution

### 2. Data Quality
- Multi-layer validation (Bronze, Silver, Gold)
- Automated data quality checks with Great Expectations
- dbt tests for business logic validation

### 3. Performance Optimization
- Adaptive Query Execution (AQE)
- Dynamic partition pruning
- Broadcast joins for dimension tables
- Z-ordering for point lookups

### 4. Monitoring & Alerting
- Real-time metrics collection
- Custom dashboards for each layer
- Automated alerting for failures and anomalies
- Distributed tracing for debugging

### 5. ML Integration
- Feature store with Feast
- Kubeflow pipelines for training
- MLflow for experiment tracking

## Deployment Architecture

### Development
- Docker Compose on local machine
- Single-node clusters for all services
- Minimal resource requirements

### Production
- Kubernetes cluster with Helm charts
- Multi-node clusters for Hadoop, Spark, Kafka
- Auto-scaling based on workload
- High availability with replication

## Security

- Network isolation via Docker networks
- TLS encryption for inter-service communication
- RBAC in Trino for data access control
- Secrets management with Vault
- Audit logging for all data access

## Scalability Considerations

### Horizontal Scaling
- Add Kafka brokers for higher throughput
- Add Spark workers for more processing power
- Add Trino workers for faster queries
- Add HDFS DataNodes for more storage

### Vertical Scaling
- Increase executor memory for large joins
- Increase Kafka partition count
- Increase Trino worker memory

## Future Enhancements

1. **Real-time Analytics**: Implement Spark Structured Streaming for Gold layer
2. **Data Lineage**: Integrate Apache Atlas for metadata management
3. **Multi-Region**: Deploy across multiple regions for disaster recovery
4. **Advanced ML**: Implement online feature serving with Feast
5. **Cost Optimization**: Implement data lifecycle policies (hot → warm → cold)
