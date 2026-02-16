# Runbook: Pipeline Failure

## Overview
This runbook provides step-by-step instructions for diagnosing and resolving pipeline failures in the SnappTrip Data Platform.

## Symptoms
- Airflow DAG shows failed tasks
- Alert received from Alertmanager
- Data freshness metrics show lag > 1 hour
- Missing data in Gold layer

## Diagnosis Steps

### 1. Check Airflow UI
```bash
# Access Airflow UI
http://localhost:8080

# Check DAG run status
# Look for red (failed) tasks
# Click on task to view logs
```

### 2. Check Spark Job Logs
```bash
# View Spark application logs
docker logs spark-master

# Check specific job logs
docker exec spark-master cat /opt/spark/logs/[app-id]
```

### 3. Check Kafka Consumer Lag
```bash
# Check consumer group lag
docker exec kafka-1 kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --describe --group bronze-consumer
```

### 4. Check HDFS Health
```bash
# Check HDFS status
docker exec namenode hdfs dfsadmin -report

# Check for corrupt blocks
docker exec namenode hdfs fsck / -files -blocks
```

## Common Issues & Solutions

### Issue 1: Spark Job Out of Memory
**Symptoms**: `java.lang.OutOfMemoryError` in Spark logs

**Solution**:
```bash
# Increase executor memory in Airflow DAG
executor_memory='8g'  # Increase from 4g

# Or reduce data volume per batch
.option("maxOffsetsPerTrigger", 5000)  # Reduce from 10000
```

### Issue 2: Kafka Consumer Lag
**Symptoms**: Consumer lag > 100K messages

**Solution**:
```bash
# Scale up Spark executors
spark.dynamicAllocation.maxExecutors=15  # Increase from 10

# Or increase processing frequency
schedule_interval='*/10 * * * *'  # Every 10 minutes instead of 15
```

### Issue 3: HDFS DataNode Down
**Symptoms**: `DataNode not responding` in logs

**Solution**:
```bash
# Restart DataNode
docker restart datanode

# Check HDFS health
docker exec namenode hdfs dfsadmin -report
```

### Issue 4: Schema Registry Connection Failed
**Symptoms**: `SchemaRegistryClient connection refused`

**Solution**:
```bash
# Restart Schema Registry
docker restart schema-registry

# Verify Schema Registry is running
curl http://localhost:8081/subjects
```

### Issue 5: Data Quality Check Failed
**Symptoms**: Great Expectations validation failure

**Solution**:
```bash
# View validation results
open great_expectations/uncommitted/data_docs/local_site/index.html

# Check specific expectation
# Fix data issue at source or update expectation
```

## Recovery Procedures

### Full Pipeline Restart
```bash
# Stop all services
docker-compose -f docker/docker-compose.yml down

# Start all services
docker-compose -f docker/docker-compose.yml up -d

# Wait for services to be ready (5 minutes)
sleep 300

# Trigger DAG manually
airflow dags trigger silver_transformation
```

### Reprocess Failed Batch
```bash
# Clear failed task in Airflow
airflow tasks clear silver_transformation \
    --start-date 2025-01-01 \
    --end-date 2025-01-02

# Trigger DAG
airflow dags trigger silver_transformation
```

### Backfill Historical Data
```bash
# Run backfill for date range
airflow dags backfill silver_transformation \
    --start-date 2025-01-01 \
    --end-date 2025-01-31
```

## Escalation

If issue persists after following this runbook:

1. **Severity P1 (Critical)**: Page on-call engineer via PagerDuty
2. **Severity P2 (High)**: Post in #data-engineering Slack channel
3. **Severity P3 (Medium)**: Create Jira ticket for data team

## Post-Incident

1. Document root cause in incident report
2. Update runbook with new learnings
3. Implement preventive measures
4. Review and update alerts if needed

## Related Runbooks
- [Data Quality Failure](data_quality_failure.md)
- [Cluster Scaling](cluster_scaling.md)
- [Disaster Recovery](disaster_recovery.md)
