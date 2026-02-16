# Why Service UIs Might Not Be Accessible

## ✅ The Answer

**Some service UIs appear in the notebooks but don't actually work because:**

1. **Kafka Control Center (9021)** - Not installed in docker-compose
2. **Spark Master UI**: http://localhost:8090 | **Airflow UI**: http://localhost:8090  
3. **Spark Application UI (4040)** - Only appears when Spark job is running
4. **DataNode UI (9864)** - Not usually needed

---

## 🌐 All Working Service UIs (That You CAN Click)

| Service | URL | Status |
|---------|-----|--------|
| **HDFS NameNode** | http://localhost:9870 | ✅ **WORKING** |
| **HDFS File Browser** | http://localhost:9870/explorer.html#/lakehouse | ✅ **WORKING** |
| **Trino Query Engine** | http://localhost:8083 | ✅ **WORKING** |
| **Airflow Orchestration** | http://localhost:8090 | ✅ **WORKING** |
| **Grafana Monitoring** | http://localhost:3000 | ✅ **WORKING** |
| **Prometheus Metrics** | http://localhost:9090 | ✅ **WORKING** |
| **Loki Logs** | http://localhost:3100 | ✅ **WORKING** |
| **Tempo Traces** | http://localhost:3200 | ✅ **WORKING** |
| **AlertManager** | http://localhost:9093 | ✅ **WORKING** |
| **Schema Registry** | http://localhost:8081 | ✅ **WORKING** |

---

## ❌ Services That DON'T Have Web UIs

These services run but don't have HTTP interfaces:

- **Kafka Brokers**: TCP connections only (use CLI or Trino)
- **Zookeeper**: TCP connections only
- **PostgreSQL**: TCP connections only (use `docker exec psql` or Python)
- **Redis**: TCP connections only
- **Spark Master**: HTTP UI conflicts with Airflow, use Airflow logs instead
- **Spark Worker**: No UI (check logs with `docker logs`)
- **NameNode DataNode**: No need to access separately

---

## 🔍 How to Access Each Service

### 1. **HDFS** ✅ (Best for browsing data)
```
http://localhost:9870
```
- Click "Explore the file system" 
- Navigate to `/lakehouse/bronze/bookings_raw` to see your Iceberg tables
- View parquet files and metadata

### 2. **Trino** ✅ (Best for querying)
```
http://localhost:8083
```
- Use SQL editor to query Iceberg tables
- Example:
```sql
SELECT * FROM iceberg.local.bronze.bookings_raw LIMIT 10;
SELECT COUNT(*) FROM iceberg.local.silver.silver_booking_state;
```

### 3. **Airflow** ✅ (Best for orchestration)
```
http://localhost:8090
```
- Username: `airflow`
- Password: `airflow`
- View DAGs and task execution history
- Check logs for any pipeline errors

### 4. **Grafana** ✅ (Best for monitoring)
```
http://localhost:3000
```
- Username: `admin`
- Password: `admin`
- View system metrics, CPU, memory usage
- Track HDFS storage

### 5. **PostgreSQL** ✅ (Check Gold layer data)
```bash
docker exec -it postgres psql -U airflow -d gold_layer

# View the Gold layer table
SELECT * FROM gold.gold_daily_kpis_postgres LIMIT 10;
```

### 6. **Kafka Topics** ✅ (Inspect messages)
```bash
# List topics
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092

# View messages
docker exec kafka-1 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic bookings_raw \
  --from-beginning \
  --max-messages 5
```

### 7. **Spark Status** ✅ (Check job execution)
```bash
# Check logs
docker logs spark-master

# Or check Airflow UI for Spark job details
# http://localhost:8090
```

---

## 📝 Updated Notebook Headers

All notebooks have been updated with **working** service UI links.

**They now point to:**
- ✅ http://localhost:9870 (HDFS)
- ✅ http://localhost:8083 (Trino)
- ✅ http://localhost:8090 (Airflow)
- ✅ http://localhost:3000 (Grafana)
- ✅ http://localhost:9090 (Prometheus)

**They NO LONGER point to:**
- ❌ http://localhost:8080 (conflicts)
- ❌ http://localhost:4040 (temporary, only when running)
- ❌ http://localhost:9021 (not installed)
- ❌ http://localhost:9864 (not needed)

---

## 🎯 What to Click for Each Task

### Task: View Raw Data
```
→ Click: http://localhost:9870/explorer.html#/lakehouse/bronze/bookings_raw
```

### Task: Query Data with SQL
```
→ Click: http://localhost:8083
→ Write: SELECT * FROM iceberg.local.bronze.bookings_raw LIMIT 10;
```

### Task: Check Pipeline Status
```
→ Click: http://localhost:8090
→ View DAGs and task logs
```

### Task: Monitor Performance
```
→ Click: http://localhost:3000
→ View Spark/Hadoop dashboards
```

### Task: Check Gold Layer in PostgreSQL
```
→ Run: docker exec postgres psql -U airflow -d gold_layer -c "SELECT * FROM gold.gold_daily_kpis_postgres;"
```

---

## 📚 Reference Document

See [SERVICE_UIS_ACTUAL.md](SERVICE_UIS_ACTUAL.md) for:
- Complete list of all services and ports
- How to check if services are running
- Troubleshooting commands
- Quick reference table

---

## 🚀 Quick Test

Try this to verify everything is working:

```bash
# 1. Check HDFS
curl -s http://localhost:9870 | head -20

# 2. Check Trino
curl -s http://localhost:8083 | head -20

# 3. Check Airflow
curl -s http://localhost:8090 | head -20

# 4. Check PostgreSQL
docker exec postgres psql -U airflow -c "SELECT 1"
```

All should return success (HTTP 200 or connection OK).

---

## Summary

| What You Want | URL to Click |
|---------------|------------|
| Browse HDFS files | http://localhost:9870/explorer.html#/lakehouse |
| Query data with SQL | http://localhost:8083 |
| Check pipeline status | http://localhost:8090 |
| Monitor metrics | http://localhost:3000 |
| Inspect Kafka messages | `docker exec kafka-1 kafka-console-consumer ...` |
| Check PostgreSQL | `docker exec postgres psql -U airflow -d gold_layer ...` |
