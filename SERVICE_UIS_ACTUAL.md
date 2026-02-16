# Service UIs - Actual Working URLs

**Make sure all Docker services are running first:**
```bash
cd docker/
make docker-up
```

---

## ✅ Working Service UIs

### Hadoop / HDFS
- **HDFS NameNode UI**: http://localhost:9870 ✅
  - Cluster status, datanodes, storage capacity
  - **Direct File Browser**: http://localhost:9870/explorer.html#/lakehouse
- **HDFS Port**: 9000 (for internal connections)

### Trino (Query Engine)
- **Trino UI**: http://localhost:8083 ✅
  - Query editor and execution
  - View running/completed queries
- **Trino Port**: 8080 (internal)

### Spark
- **Spark Master UI**: http://localhost:8082 ✅
- **Spark Application UI**: http://localhost:4040 (when local Spark job is running)
- **Spark Master Port**: 7077 (for internal connections)

### Airflow
- **Airflow UI**: http://localhost:8090 ✅
  - **Username**: `airflow`
  - **Password**: `airflow`
  - View DAGs, task instances, logs
- **Airflow Port**: 8080 (internal)

### Grafana (Monitoring)
- **Grafana UI**: http://localhost:3000 ✅
  - **Username**: `admin`
  - **Password**: `admin`
  - Dashboards for monitoring
- Can see Spark/Hadoop metrics if properly configured

### Kafka Services
- **Schema Registry**: http://localhost:8081 ✅
  - Avro schemas for Kafka messages
- **Kafka Broker Ports** (for client connections):
  - kafka-1: localhost:19092
  - kafka-2: localhost:19093
  - kafka-3: localhost:19094
- **Zookeeper**: localhost:2181 (TCP, no UI)

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

**Access via CLI**:
```bash
docker exec -it postgres psql -U airflow -d gold_layer
```

### Other Services
- **Redis**: localhost:6379 (TCP, no UI)
- **Prometheus**: http://localhost:9090 ✅
  - Metrics collection
- **Loki**: http://localhost:3100 ✅
  - Log aggregation
- **Tempo**: http://localhost:3200 ✅
  - Trace collection
- **AlertManager**: http://localhost:9093 ✅
  - Alert management

---

## 📊 Service Summary Table

| Service | URL | Status | Notes |
|---------|-----|--------|-------|
| **HDFS NameNode** | http://localhost:9870 | ✅ Working | File browser at /explorer.html#/lakehouse |
| **Trino** | http://localhost:8083 | ✅ Working | Query editor |
| **Airflow** | http://localhost:8090 | ✅ Working | airflow/airflow |
| **Grafana** | http://localhost:3000 | ✅ Working | admin/admin |
| **Spark Master** | http://localhost:8082 | ✅ Working | Spark cluster UI |
| **Spark App** | http://localhost:4040 | ⚠️ Temporary | Only when job running |
| **Schema Registry** | http://localhost:8081 | ✅ Working | Kafka schemas |
| **Prometheus** | http://localhost:9090 | ✅ Working | Metrics |
| **Loki** | http://localhost:3100 | ✅ Working | Logs |
| **Tempo** | http://localhost:3200 | ✅ Working | Traces |
| **PostgreSQL** | localhost:5432 | ✅ Working | psql CLI only |
| **Kafka Brokers** | localhost:19092-19094 | ✅ Working | Client connections |
| **Zookeeper** | localhost:2181 | ✅ Working | TCP only |

---

## 🔍 How to Access Each Service

### 1. HDFS File Browser
```
http://localhost:9870/explorer.html#/lakehouse
```
- Navigate through Bronze, Silver, Gold layers
- View Iceberg table metadata
- Check file sizes and replication

### 2. Trino Query Editor
```
http://localhost:8083
```
- Write SQL queries to test data
- Query Iceberg tables directly
- Example:
```sql
SELECT * FROM iceberg.local.bronze.bookings_raw LIMIT 10;
```

### 3. Airflow DAGs
```
http://localhost:8090
```
- View pipeline execution history
- Monitor task status
- Check logs for errors

### 4. Grafana Dashboards
```
http://localhost:3000
```
- Monitor Spark jobs
- Track HDFS usage
- View system metrics

### 5. PostgreSQL Database
```bash
# Via CLI
docker exec -it postgres psql -U airflow -d gold_layer

# View Gold layer data
SELECT * FROM gold.gold_daily_kpis_postgres LIMIT 10;
```

### 6. Kafka Message Inspection
```bash
# List topics
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092

# Consume messages
docker exec kafka-1 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic bookings_raw \
  --from-beginning \
  --max-messages 5

# Check topic metadata
docker exec kafka-1 kafka-topics --describe \
  --topic bookings_raw \
  --bootstrap-server localhost:9092
```

### 7. Spark Master Status
```bash
# Check Spark logs
docker logs spark-master

# Alternative: Check via Airflow UI at http://localhost:8090
# Look for Spark application logs
```

---

## 🚨 Troubleshooting Why UIs Don't Load

### Issue: Finding Airflow vs Spark UIs
**Ports**: 
- **Airflow UI**: http://localhost:8090
- **Spark Master UI**: http://localhost:8082

### Issue: Spark Application UI not accessible
**Solution**:
- Port 4040 only opens when a Spark job is running
- Check notebook output for Spark job status
- Alternative: Check logs with `docker logs spark-master`

### Issue: Service timeout/connection refused
**Solution**:
```bash
# Check if containers are running
docker ps | grep <service-name>

# Check container logs
docker logs <container-name>

# Restart all services
cd docker/
make docker-down
make docker-up
```

### Issue: HDFS shows "Connection refused"
**Solution**:
```bash
# Check NameNode health
docker exec namenode hdfs dfsadmin -report

# Check if in safe mode
docker exec namenode hdfs dfsadmin -safemode get

# Leave safe mode if needed
docker exec namenode hdfs dfsadmin -safemode leave
```

### Issue: PostgreSQL not accessible
**Solution**:
```bash
# Test connection
docker exec postgres psql -U airflow -c "SELECT 1"

# Check database exists
docker exec postgres psql -U airflow -c "\l"

# Check if gold_layer database exists
docker exec postgres psql -U airflow -c "\c gold_layer"
```

---

## 📚 Quick Reference

### Check All Services Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### View Service Logs
```bash
docker logs <service-name>  # Last 100 lines
docker logs -f <service-name>  # Follow logs (live)
docker logs --tail 50 <service-name>  # Last 50 lines
```

### Restart a Service
```bash
docker restart <service-name>
```

### Restart All Services
```bash
cd docker/
make docker-down  # Stop all
make docker-up    # Start all
```

---

## ✅ Recommended Access Order

1. **Start**: Verify HDFS is working
   - Visit: http://localhost:9870
   - Navigate to `/lakehouse` to see your data

2. **Monitor**: Check Airflow for pipeline status
   - Visit: http://localhost:8090
   - View task logs

3. **Query**: Use Trino to query data directly
   - Visit: http://localhost:8083
   - Write SQL queries

4. **Analyze**: View metrics in Grafana
   - Visit: http://localhost:3000
   - Check Spark/Hadoop dashboards

5. **Verify**: Check PostgreSQL for Gold layer
   - Use: `docker exec postgres psql -U airflow -d gold_layer -c "SELECT * FROM gold.gold_daily_kpis_postgres LIMIT 5"`

---

## 🎯 What to Do if a Service is Down

### Kafka Issues
```bash
# Restart Kafka cluster
docker restart kafka-1 kafka-2 kafka-3 zookeeper

# Verify topics still exist
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092
```

### HDFS Issues
```bash
# Restart HDFS
docker restart namenode datanode

# Check health
docker exec namenode hdfs dfsadmin -report
```

### Spark Issues
```bash
# Check Spark Master
docker logs spark-master

# Restart if needed
docker restart spark-master spark-worker-1 spark-worker-2
```

### PostgreSQL Issues
```bash
# Restart PostgreSQL
docker restart postgres

# Verify connection
docker exec postgres psql -U airflow -c "SELECT 1"
```

---

## 📞 Need Help?

Check these documents:
- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) - Architecture details
- [QUICK_START.md](QUICK_START.md) - Step-by-step setup
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - What was built
- [README.md](README.md) - Project overview

Or run diagnostics:
```bash
cd docker/
docker ps  # Check running containers
docker logs <container-name>  # Check service logs
```
