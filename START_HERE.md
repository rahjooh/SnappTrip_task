# START HERE - Service UIs That Actually Work

## ⚠️ Important: Why Some URLs Don't Work

Your Docker services are running, but **not all URLs in notebooks are accessible** because:

1. **Kafka UI (9021)** - NOT installed
   - ✅ Use **Trino (9083)** instead to query data

2. **Spark Master**: http://localhost:8082
   - **Airflow**: http://localhost:8090

3. **Spark App (4040)** - Only appears when job is running
   - ✅ Check notebook output for status

4. **DataNode (9864)** - Not needed
   - ✅ Use NameNode (9870) instead

---

## ✅ Actual Working URLs - Copy & Paste These!

### 1. HDFS File Browser (Most Important!)
```
http://localhost:9870/explorer.html#/lakehouse
```
- View your Bronze, Silver, Gold Iceberg tables
- See file sizes and structure

### 2. Query Data with Trino
```
http://localhost:8083
```
- Write SQL queries to test data
- Example:
```sql
SELECT * FROM iceberg.local.bronze.bookings_raw LIMIT 5;
```

### 3. Check Pipeline Status (Airflow)
```
http://localhost:8888
```
- Username: `airflow`
- Password: `airflow`
- View logs and task status

### 4. Monitor Metrics (Grafana)
```
http://localhost:3000
```
- Username: `admin`
- Password: `admin`
- View Spark and Hadoop metrics

### 5. View Raw Metrics (Prometheus)
```
http://localhost:9090
```

### 6. View HDFS Status
```
http://localhost:9870
```

---

## 🖥️ Services WITHOUT Web UIs (Use CLI)

### PostgreSQL - Check Gold Layer Data
```bash
docker exec -it postgres psql -U airflow -d gold_layer
SELECT * FROM gold.gold_daily_kpis_postgres LIMIT 10;
```

### Kafka - Inspect Messages
```bash
# List topics
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092

# View messages
docker exec kafka-1 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic bookings_raw \
  --from-beginning --max-messages 5
```

### HDFS - Command Line
```bash
# List files
docker exec namenode hdfs dfs -ls /lakehouse

# List with details
docker exec namenode hdfs dfs -ls -R /lakehouse/bronze/bookings_raw
```

---

## 📋 Quick Reference Table

| Service | URL | Works? | Use For |
|---------|-----|--------|---------|
| HDFS Browser | http://localhost:9870/explorer.html#/lakehouse | ✅ Yes | Browse files |
| HDFS Status | http://localhost:9870 | ✅ Yes | Cluster health |
| Trino | http://localhost:8083 | ✅ Yes | Query data |
| Airflow | http://localhost:8090 | ✅ Yes | Pipeline status |
| Grafana | http://localhost:3000 | ✅ Yes | Monitoring |
| Prometheus | http://localhost:9090 | ✅ Yes | Metrics |
| Schema Registry | http://localhost:8081 | ✅ Yes | Kafka schemas |
| Spark Master | http://localhost:8082 | ✅ Yes | Spark cluster UI |
| Spark App | http://localhost:4040 | ❌ Temporary | Check notebook |
| Kafka UI | http://localhost:9021 | ❌ No | Use Trino |
| DataNode | http://localhost:9864 | ❌ No | Use NameNode |

---

## 🎯 First Things to Try

1. **View Data in HDFS**
   ```
   http://localhost:9870/explorer.html#/lakehouse
   ```
   - Should show: bronze, reference, silver, gold directories

2. **Query Data with SQL**
   ```
   http://localhost:8083
   ```
   - Try this query:
   ```sql
   SELECT COUNT(*) FROM iceberg.local.bronze.bookings_raw;
   ```

3. **Check PostgreSQL Gold Layer**
   ```bash
   docker exec postgres psql -U airflow -d gold_layer -c \
     "SELECT COUNT(*) FROM gold.gold_daily_kpis_postgres;"
   ```

---

## 📚 More Information

- **[WORKING_URLS.txt](WORKING_URLS.txt)** - All working URLs
- **[WHY_UIS_DONT_WORK.md](WHY_UIS_DONT_WORK.md)** - Why some UIs fail
- **[SERVICE_UIS_ACTUAL.md](SERVICE_UIS_ACTUAL.md)** - Complete reference
- **[QUICK_START.md](QUICK_START.md)** - 5-minute setup guide
- **[PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)** - Architecture details

---

## ✅ Summary

**Use these URLs:**
- ✅ http://localhost:9870/explorer.html#/lakehouse (HDFS)
- ✅ http://localhost:8083 (Trino)
- ✅ http://localhost:8090 (Airflow)
- ✅ http://localhost:3000 (Grafana)

**Don't use these:**
- ❌ http://localhost:8080 (conflicts)
- ❌ http://localhost:4040 (temporary)
- ❌ http://localhost:9021 (not installed)

**Everything else:** Use CLI commands (see above)

---

**Happy data exploring!** 🚀
