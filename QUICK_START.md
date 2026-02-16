# Quick Start Guide

Get the SnappTrip Data Platform running in 5 minutes!

---

## Prerequisites

- Docker Desktop installed and running
- Python 3.11+ with pip
- Jupyter Notebook
- 8GB RAM minimum
- 20GB free disk space

---

## Step 1: Start Docker Services (2 minutes)

```bash
cd docker/
make docker-up
```

**Wait for services to start** (~2 minutes). You should see:
```
✅ kafka-1, kafka-2, kafka-3 (Kafka brokers)
✅ zookeeper (Kafka coordination)
✅ namenode, datanode (HDFS)
✅ spark-master, spark-worker (Spark cluster)
✅ postgres (PostgreSQL database)
✅ trino-coordinator (Query engine)
✅ airflow-webserver (Orchestration)
✅ grafana (Monitoring)
```

**Verify services**:
```bash
docker ps  # Should show 10+ containers running
```

---

## Step 2: Install Python Dependencies (1 minute)

```bash
# Install main dependencies
pip install -r requirements.txt

# Install DBT dependencies
pip install -r requirements-dbt.txt

# Install DBT packages
cd dbt/
dbt deps
cd ..
```

---

## Step 3: Create Kafka Topics (30 seconds)

```bash
# Create topics for bookings, events, and hotels
docker exec kafka-1 kafka-topics --create --if-not-exists \
  --topic bookings_raw --partitions 3 --replication-factor 3 \
  --bootstrap-server localhost:9092

docker exec kafka-1 kafka-topics --create --if-not-exists \
  --topic booking_events_raw --partitions 3 --replication-factor 3 \
  --bootstrap-server localhost:9092

docker exec kafka-1 kafka-topics --create --if-not-exists \
  --topic hotels_raw --partitions 1 --replication-factor 3 \
  --bootstrap-server localhost:9092
```

**Verify topics**:
```bash
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092
# Should show: bookings_raw, booking_events_raw, hotels_raw
```

---

## Step 4: Run the Pipeline (5 minutes)

### 4.1 Produce Data to Kafka

```bash
jupyter notebook notebooks/01_kafka_service.ipynb
```

**Run all cells** (Kernel → Restart & Run All)

✅ **Expected Output**:
- Loaded 10 bookings
- Loaded 11 events
- Loaded 3 hotels
- Produced 24 messages to Kafka

---

### 4.2 Ingest to Bronze Layer (HDFS)

```bash
jupyter notebook notebooks/02_bronze_layer.ipynb
```

**Run all cells**

✅ **Expected Output**:
- Spark session initialized
- Read 10 bookings from Kafka
- Read 11 events from Kafka
- Read 3 hotels from Kafka
- Written to HDFS Iceberg (Snappy Parquet)
- HDFS paths displayed

**Verify in HDFS UI**: http://localhost:9870/explorer.html#/lakehouse

---

### 4.3 Transform to Silver Layer (DBT)

```bash
jupyter notebook notebooks/03_silver_layer.ipynb
```

**Run all cells**

✅ **Expected Output**:
- DBT run completed successfully
- Silver layer table created
- All data quality tests passed
- HDFS path displayed

---

### 4.4 Aggregate to Gold Layer (DBT + PostgreSQL)

```bash
jupyter notebook notebooks/04_gold_layer.ipynb
```

**Run all cells**

✅ **Expected Output**:
- DBT run completed successfully (HDFS)
- DBT run completed successfully (PostgreSQL)
- All data quality tests passed
- KPI visualizations generated
- HDFS path displayed

---

## Step 5: Verify Results

### Check HDFS Storage

```bash
docker exec namenode hdfs dfs -ls -R /lakehouse
```

**Expected directories**:
```
/lakehouse/bronze/bookings_raw
/lakehouse/bronze/booking_events_raw
/lakehouse/reference/hotels
/lakehouse/silver/silver_booking_state
/lakehouse/gold/gold_daily_kpis_v2
```

### Check PostgreSQL

```bash
docker exec postgres psql -U airflow -d gold_layer -c \
  "SELECT COUNT(*) FROM gold.gold_daily_kpis_postgres;"
```

**Expected**: 6 rows (2 dates × 3 cities)

### View Data in Spark

```python
# In any Jupyter notebook with Spark session
spark.table("local.silver.silver_booking_state").show()
spark.table("local.gold.gold_daily_kpis_v2").show()
```

---

## 🌐 Access Service UIs

All services are now accessible:

| Service | URL | Credentials |
|---------|-----|-------------|
| **HDFS Explorer** | http://localhost:9870/explorer.html#/lakehouse | - |
| **Spark Master** | http://localhost:8080 | - |
| **Spark Application** | http://localhost:4040 | - |
| **Kafka Control Center** | http://localhost:9021 | - |
| **Trino** | http://localhost:8081 | - |
| **Airflow** | http://localhost:8090 | airflow/airflow |
| **Grafana** | http://localhost:3000 | admin/admin |

---

## 🎯 What You Just Built

```
CSV Files (24 records)
    ↓
Kafka Topics (3 topics, 24 messages)
    ↓
Bronze Layer (HDFS Iceberg, Snappy Parquet)
    ↓
Silver Layer (HDFS Iceberg, Snappy Parquet, DBT)
    ↓
Gold Layer (HDFS Iceberg + PostgreSQL, DBT)
```

**Features**:
- ✅ Medallion Architecture (Bronze → Silver → Gold)
- ✅ All data persisted in HDFS Iceberg format
- ✅ Snappy Parquet compression throughout
- ✅ DBT transformations with data quality tests
- ✅ Dual output (HDFS + PostgreSQL) at Gold layer
- ✅ Complete lineage tracking

---

## 🔍 Troubleshooting

### Issue: Docker containers not starting

```bash
# Check Docker Desktop is running
docker ps

# Restart Docker Desktop
# Then retry: make docker-up
```

### Issue: Kafka connection failed

```bash
# Check Kafka brokers
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server localhost:9092

# If failed, restart Kafka
cd docker/
make docker-down
make docker-up
```

### Issue: HDFS connection failed

```bash
# Check NameNode
docker exec namenode hdfs dfsadmin -report

# If in safe mode
docker exec namenode hdfs dfsadmin -safemode leave
```

### Issue: DBT run failed

```bash
# Check DBT configuration
cd dbt/
dbt debug --profiles-dir . --profile snapptrip --target local

# Check Spark session in notebook
# Ensure Spark is initialized before running DBT cells
```

### Issue: PostgreSQL connection failed

```bash
# Check PostgreSQL
docker exec postgres psql -U airflow -c "SELECT 1"

# Check database exists
docker exec postgres psql -U airflow -c "\l"
```

---

## 📚 Next Steps

1. **Explore Data Lineage**:
   ```bash
   cd dbt/
   dbt docs generate
   dbt docs serve  # Opens http://localhost:8080
   ```

2. **Run Data Quality Tests**:
   ```bash
   cd dbt/
   dbt test --select tag:silver
   dbt test --select tag:gold
   ```

3. **View Complete Documentation**:
   - [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) - Architecture details
   - [SERVICE_UIS.md](SERVICE_UIS.md) - Service UI reference
   - [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Implementation summary

4. **Customize the Pipeline**:
   - Add more CSV files to `data/`
   - Modify DBT models in `dbt/models/`
   - Add custom data quality tests in `dbt/models/*/schema.yml`

---

## 🎉 Success!

You now have a fully functional data platform with:
- ✅ Streaming data ingestion (Kafka)
- ✅ Distributed storage (HDFS)
- ✅ Lakehouse format (Iceberg)
- ✅ Data transformations (DBT)
- ✅ Data quality (DBT tests)
- ✅ Analytics layer (PostgreSQL)
- ✅ Lineage tracking (DBT docs)

**Total setup time**: ~10 minutes

**For questions or issues**, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or check service logs:
```bash
docker logs <container-name>
```
