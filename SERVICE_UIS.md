# Service UIs Quick Reference

All services are accessible after running `make docker-up` in the `docker/` directory.

## 🌐 Web Interfaces

### Spark
- **Spark Master UI**: http://localhost:8080
  - View cluster status, workers, running applications
- **Spark Application UI**: http://localhost:4040
  - View jobs, stages, storage, environment (only when app is running)

### Hadoop / HDFS
- **Hadoop NameNode UI**: http://localhost:9870
  - View HDFS status, datanodes, storage capacity
- **Hadoop DataNode UI**: http://localhost:9864
  - View datanode status, blocks
- **HDFS File Explorer**: http://localhost:9870/explorer.html#/lakehouse
  - Browse HDFS files directly in browser
  - Navigate to `/lakehouse` to see Bronze/Silver/Gold layers

### Kafka
- **Kafka Control Center**: http://localhost:9021
  - View topics, consumer groups, brokers
  - Monitor message throughput
- **Zookeeper**: http://localhost:2181
  - Zookeeper admin interface

### Trino
- **Trino UI**: http://localhost:8081
  - Query editor and execution monitoring
  - View running/completed queries

### Airflow
- **Airflow UI**: http://localhost:8090
  - **Username**: `airflow`
  - **Password**: `airflow`
  - View DAGs, task instances, logs

### Grafana
- **Grafana UI**: http://localhost:3000
  - **Username**: `admin`
  - **Password**: `admin`
  - Dashboards for monitoring

### DBT Documentation
- **DBT Docs**: http://localhost:8080 (after running `dbt docs serve`)
  - View data lineage
  - Browse models, sources, tests
  - Interactive DAG visualization

## 🔌 Database Connections

### PostgreSQL
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `gold_layer`
- **Username**: `airflow`
- **Password**: `airflow`

**Connection String**:
```
postgresql://airflow:airflow@localhost:5432/gold_layer
```

**psql CLI**:
```bash
docker exec -it postgres psql -U airflow -d gold_layer
```

**Python (psycopg)**:
```python
import psycopg
conn = psycopg.connect(
    host="localhost",
    port=5432,
    dbname="gold_layer",
    user="airflow",
    password="airflow"
)
```

### HDFS
- **NameNode**: `hdfs://localhost:9000`
- **NameNode (from Docker)**: `hdfs://namenode:9000`

**HDFS CLI**:
```bash
# List files
docker exec namenode hdfs dfs -ls /lakehouse

# View file content
docker exec namenode hdfs dfs -cat /lakehouse/bronze/bookings_raw/metadata/version-hint.text

# Check disk usage
docker exec namenode hdfs dfs -du -h /lakehouse
```

### Kafka
- **Bootstrap Servers (external)**: `localhost:19092,localhost:19093,localhost:19094`
- **Bootstrap Servers (internal)**: `kafka-1:9092,kafka-2:9092,kafka-3:9092`

**Kafka CLI**:
```bash
# List topics
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092

# Describe topic
docker exec kafka-1 kafka-topics --describe --topic bookings_raw --bootstrap-server localhost:9092

# Consume messages
docker exec kafka-1 kafka-console-consumer --bootstrap-server localhost:9092 --topic bookings_raw --from-beginning --max-messages 5
```

## 📊 Monitoring Checklist

### Before Running Pipeline
- [ ] All Docker containers running: `docker ps`
- [ ] Kafka brokers healthy: http://localhost:9021
- [ ] HDFS NameNode active: http://localhost:9870
- [ ] Spark Master running: http://localhost:8080
- [ ] PostgreSQL accessible: `docker exec postgres psql -U airflow -c "SELECT 1"`

### During Pipeline Execution
- [ ] Kafka messages produced: Check topic offsets in Control Center
- [ ] HDFS files created: Browse http://localhost:9870/explorer.html#/lakehouse
- [ ] Spark jobs running: Check http://localhost:4040
- [ ] DBT models executed: Check notebook output

### After Pipeline Completion
- [ ] Bronze layer tables exist: `hdfs dfs -ls /lakehouse/bronze`
- [ ] Silver layer tables exist: `hdfs dfs -ls /lakehouse/silver`
- [ ] Gold layer tables exist: `hdfs dfs -ls /lakehouse/gold`
- [ ] PostgreSQL table populated: `SELECT COUNT(*) FROM gold.gold_daily_kpis_postgres`

## 🔍 Troubleshooting

### Service Not Accessible
```bash
# Check if container is running
docker ps | grep <service-name>

# Check container logs
docker logs <container-name>

# Restart service
cd docker/
make docker-down
make docker-up
```

### HDFS Connection Issues
```bash
# Check NameNode status
docker exec namenode hdfs dfsadmin -report

# Check NameNode logs
docker logs namenode

# Safe mode (if stuck)
docker exec namenode hdfs dfsadmin -safemode leave
```

### Kafka Connection Issues
```bash
# Check broker status
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server localhost:9092

# Check Zookeeper
docker exec zookeeper zkCli.sh ls /brokers/ids
```

### PostgreSQL Connection Issues
```bash
# Test connection
docker exec postgres psql -U airflow -d gold_layer -c "\dt"

# Check logs
docker logs postgres
```

## 🎯 Quick Actions

### View Latest Data

**Bronze Layer (HDFS)**:
```bash
docker exec namenode hdfs dfs -ls -R /lakehouse/bronze/bookings_raw | tail -20
```

**Silver Layer (Spark SQL)**:
```python
# In Jupyter notebook
spark.sql("SELECT * FROM local.silver.silver_booking_state LIMIT 10").show()
```

**Gold Layer (PostgreSQL)**:
```sql
-- In psql or notebook
SELECT * FROM gold.gold_daily_kpis_postgres ORDER BY booking_date DESC LIMIT 10;
```

### Check Data Quality

**DBT Tests**:
```bash
cd dbt/
dbt test --select tag:silver  # Silver layer tests
dbt test --select tag:gold    # Gold layer tests
```

**Iceberg Snapshots**:
```python
# In Jupyter notebook
spark.sql("SELECT * FROM local.silver.silver_booking_state.snapshots").show()
```

### Monitor Performance

**Spark UI** (http://localhost:4040):
- Jobs tab: View job execution time
- Stages tab: View stage-level metrics
- Storage tab: View cached data
- SQL tab: View query plans

**HDFS UI** (http://localhost:9870):
- Overview: Cluster capacity, live nodes
- Datanodes: Storage usage per node
- Utilities > Browse: File sizes and replication

**Kafka Control Center** (http://localhost:9021):
- Topics: Message rate, consumer lag
- Brokers: Throughput, partition distribution

---

## 📚 Additional Resources

- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) - Complete pipeline documentation
- [README.md](README.md) - Project overview and setup
- [GETTING_STARTED.md](GETTING_STARTED.md) - Quick start guide
- [DBT_PIPELINE_GUIDE.md](DBT_PIPELINE_GUIDE.md) - DBT-specific documentation
