# SnappTrip Data Pipeline Architecture

## Overview

This is a complete data engineering pipeline implementing the Medallion Architecture (Bronze → Silver → Gold) with:
- **Apache Kafka** for streaming data ingestion
- **Apache Spark** for data processing
- **Apache Iceberg** for lakehouse storage format
- **HDFS** for distributed storage
- **DBT** for data transformations and quality
- **PostgreSQL** for analytics layer
- **Snappy Parquet** compression throughout

## Architecture Diagram

```
CSV Files (data/)
    ↓
Kafka Topics (bookings_raw, booking_events_raw, hotels_raw)
    ↓
Bronze Layer (HDFS Iceberg - Snappy Parquet)
    ↓
Silver Layer (HDFS Iceberg - Snappy Parquet) [via DBT]
    ↓
Gold Layer (HDFS Iceberg + PostgreSQL) [via DBT]
    ↓
Analytics/BI Tools
```

## Data Flow

### 1. Kafka Service (01_kafka_service.ipynb)
**Purpose**: Ingest all CSV data into Kafka topics

**Input**: 
- `data/bookings_raw.csv` (10 records)
- `data/booking_events_raw.csv` (11 records)
- `data/hotels_raw.csv` (3 records)

**Output**:
- Kafka Topic: `bookings_raw` (3 partitions, RF=3)
- Kafka Topic: `booking_events_raw` (3 partitions, RF=3)
- Kafka Topic: `hotels_raw` (1 partition, RF=3)

**Technology**: Python, confluent-kafka

---

### 2. Bronze Layer (02_bronze_layer.ipynb)
**Purpose**: Raw data ingestion from Kafka to HDFS Iceberg

**Input**: Kafka topics (bookings_raw, booking_events_raw, hotels_raw)

**Processing**:
- Read from Kafka using Spark Structured Streaming
- Parse JSON messages
- Add processing timestamps
- Write to Iceberg tables

**Output**:
- `hdfs://namenode:9000/lakehouse/bronze/bookings_raw` (Iceberg, Snappy Parquet)
- `hdfs://namenode:9000/lakehouse/bronze/booking_events_raw` (Iceberg, Snappy Parquet)
- `hdfs://namenode:9000/lakehouse/reference/hotels` (Iceberg, Snappy Parquet)

**Technology**: PySpark, Iceberg, HDFS

**Partitioning**:
- bookings_raw: Partitioned by `created_at_ts`
- booking_events_raw: Partitioned by `event_ts_parsed`
- hotels: No partitioning (small reference table)

---

### 3. Silver Layer (03_silver_layer.ipynb)
**Purpose**: Data cleansing, deduplication, enrichment via DBT

**Input**: 
- `hdfs://namenode:9000/lakehouse/bronze/bookings_raw`
- `hdfs://namenode:9000/lakehouse/reference/hotels`

**Processing** (via DBT model `silver_booking_state.sql`):
1. **Deduplication**: Keep latest record per booking_id using ROW_NUMBER()
2. **Enrichment**: Join with hotels reference data (city, star_rating)
3. **Validation**: Apply business rules
   - price > 0
   - status IN ('created', 'confirmed', 'cancelled')
   - created_at <= updated_at
   - Not null constraints
4. **Incremental Load**: Merge strategy based on processing_ts

**Output**:
- `hdfs://namenode:9000/lakehouse/silver/silver_booking_state` (Iceberg, Snappy Parquet)

**Technology**: DBT, Spark, Iceberg

**Partitioning**: By `date(created_at)`

**Data Quality Tests**:
- ✅ Unique booking_id
- ✅ Not null: booking_id, user_id, hotel_id, status, price, city
- ✅ Valid status values
- ✅ Price > 0
- ✅ created_at <= updated_at
- ✅ Hotel relationships (foreign key to reference.hotels)
- ✅ Star rating between 1-5

---

### 4. Gold Layer (04_gold_layer.ipynb)
**Purpose**: Business metrics aggregation via DBT

**Input**: 
- `hdfs://namenode:9000/lakehouse/silver/silver_booking_state`

**Processing** (via DBT model `gold_daily_kpis_v2.sql`):
1. **Aggregation**: Daily KPIs by city
   - Total bookings
   - Confirmed/cancelled/pending bookings
   - Cancellation rate (%)
   - Total revenue
   - Average prices (confirmed, all)
   - Min/max prices
   - Average star rating
   - Unique customers
2. **Incremental Load**: Merge strategy based on (booking_date, city)

**Output**:
- **HDFS**: `hdfs://namenode:9000/lakehouse/gold/gold_daily_kpis_v2` (Iceberg, Snappy Parquet)
- **PostgreSQL**: `gold_layer.gold.gold_daily_kpis_postgres` table

**Technology**: DBT, Spark, Iceberg, PostgreSQL

**Partitioning**: By `booking_date`

**Data Quality Tests**:
- ✅ Unique combination of (booking_date, city)
- ✅ Not null constraints
- ✅ Cancellation rate between 0-100%
- ✅ Revenue >= 0
- ✅ Booking counts consistency: confirmed + cancelled + pending = total
- ✅ booking_date <= CURRENT_DATE()

---

## Storage Details

### HDFS Directory Structure
```
/lakehouse/
├── bronze/
│   ├── bookings_raw/
│   │   ├── metadata/
│   │   └── data/ (Snappy Parquet files)
│   └── booking_events_raw/
│       ├── metadata/
│       └── data/ (Snappy Parquet files)
├── reference/
│   └── hotels/
│       ├── metadata/
│       └── data/ (Snappy Parquet files)
├── silver/
│   └── silver_booking_state/
│       ├── metadata/
│       └── data/ (Snappy Parquet, partitioned by date)
└── gold/
    └── gold_daily_kpis_v2/
        ├── metadata/
        └── data/ (Snappy Parquet, partitioned by date)
```

### Iceberg Format Benefits
- **ACID Transactions**: Atomic commits, isolation
- **Schema Evolution**: Add/remove columns without rewriting data
- **Time Travel**: Query historical snapshots
- **Hidden Partitioning**: Automatic partition pruning
- **Snappy Compression**: Fast compression/decompression, good ratio

### PostgreSQL Schema
```sql
Database: gold_layer
Schema: gold
Table: gold_daily_kpis_postgres

Columns:
- booking_date (DATE)
- city (VARCHAR)
- total_bookings (BIGINT)
- confirmed_bookings (BIGINT)
- cancelled_bookings (BIGINT)
- pending_bookings (BIGINT)
- cancellation_rate (NUMERIC)
- total_revenue (NUMERIC)
- avg_confirmed_price (NUMERIC)
- avg_booking_price (NUMERIC)
- min_price (NUMERIC)
- max_price (NUMERIC)
- avg_star_rating (NUMERIC)
- unique_customers (BIGINT)
- last_updated (TIMESTAMP)
- dbt_updated_at (TIMESTAMP)
```

---

## DBT Models

### Source Definitions (`dbt/models/sources.yml`)
```yaml
sources:
  - name: bronze
    tables:
      - bookings_raw
  - name: reference
    tables:
      - hotels
```

### Silver Model (`dbt/models/silver/silver_booking_state.sql`)
- Materialization: `incremental`
- File Format: `iceberg`
- Unique Key: `booking_id`
- Strategy: `merge`
- Partitioning: `date(created_at)`
- Compression: Snappy Parquet

### Gold Model (`dbt/models/gold/gold_daily_kpis_v2.sql`)
- Materialization: `incremental`
- File Format: `iceberg`
- Unique Key: `['booking_date', 'city']`
- Strategy: `merge`
- Partitioning: `booking_date`
- Compression: Snappy Parquet

### PostgreSQL Model (`dbt/models/gold/gold_daily_kpis_postgres.sql`)
- Materialization: `table`
- Target: PostgreSQL
- Reads from: `gold_daily_kpis_v2` (Iceberg)

---

## Data Quality Framework

### DBT Tests
All tests are defined in schema YAML files and run automatically with `dbt test`.

**Column-Level Tests**:
- `unique`: Ensures no duplicates
- `not_null`: Ensures no missing values
- `accepted_values`: Validates enum values
- `relationships`: Foreign key constraints
- `dbt_utils.expression_is_true`: Custom SQL expressions

**Table-Level Tests**:
- `dbt_utils.unique_combination_of_columns`: Composite keys
- `dbt_utils.expression_is_true`: Cross-column validations

**Test Execution**:
```bash
dbt test --select tag:silver  # Test Silver layer
dbt test --select tag:gold    # Test Gold layer
```

---

## Lineage Tracking

DBT automatically generates lineage documentation showing:
- Source → Model dependencies
- Model → Model dependencies
- Column-level lineage

**View Lineage**:
```bash
cd dbt/
dbt docs generate
dbt docs serve  # Opens http://localhost:8080
```

The lineage graph shows:
```
sources.bronze.bookings_raw ──┐
                               ├──> silver_booking_state ──> gold_daily_kpis_v2 ──> gold_daily_kpis_postgres
sources.reference.hotels ──────┘
```

---

## Service UIs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Spark Master** | http://localhost:8080 | - |
| **Spark Application** | http://localhost:4040 | - |
| **Hadoop NameNode** | http://localhost:9870 | - |
| **Hadoop DataNode** | http://localhost:9864 | - |
| **HDFS Explorer** | http://localhost:9870/explorer.html#/lakehouse | - |
| **Trino** | http://localhost:8081 | - |
| **Kafka Control Center** | http://localhost:9021 | - |
| **Zookeeper** | http://localhost:2181 | - |
| **Airflow** | http://localhost:8090 | airflow/airflow |
| **Grafana** | http://localhost:3000 | admin/admin |
| **PostgreSQL** | localhost:5432 | airflow/airflow |
| **DBT Docs** | http://localhost:8080 | (after `dbt docs serve`) |

---

## Running the Pipeline

### Prerequisites
```bash
# Start Docker services
cd docker/
make docker-up

# Install Python dependencies
pip install -r requirements.txt
pip install -r requirements-dbt.txt

# Install DBT packages
cd dbt/
dbt deps
```

### Execution Order

**Step 1: Produce Data to Kafka**
```bash
jupyter notebook notebooks/01_kafka_service.ipynb
# Run all cells
```
✅ Output: 24 messages in 3 Kafka topics

**Step 2: Ingest to Bronze Layer**
```bash
jupyter notebook notebooks/02_bronze_layer.ipynb
# Run all cells
```
✅ Output: 3 Iceberg tables in HDFS (Bronze + Reference)

**Step 3: Transform to Silver Layer**
```bash
jupyter notebook notebooks/03_silver_layer.ipynb
# Run all cells (executes DBT)
```
✅ Output: 1 Iceberg table in HDFS (Silver)
✅ Data Quality: All tests passed

**Step 4: Aggregate to Gold Layer**
```bash
jupyter notebook notebooks/04_gold_layer.ipynb
# Run all cells (executes DBT)
```
✅ Output: 1 Iceberg table in HDFS + 1 PostgreSQL table (Gold)
✅ Data Quality: All tests passed

---

## Monitoring & Observability

### HDFS Storage Monitoring
```bash
# Check HDFS usage
docker exec namenode hdfs dfs -du -h /lakehouse

# List all tables
docker exec namenode hdfs dfs -ls -R /lakehouse
```

### Iceberg Table Metadata
```python
# In Spark/Jupyter
spark.sql("SELECT * FROM local.bronze.bookings_raw.snapshots").show()
spark.sql("SELECT * FROM local.bronze.bookings_raw.history").show()
spark.sql("SELECT * FROM local.bronze.bookings_raw.files").show()
```

### DBT Logs
```bash
cd dbt/
dbt run --debug  # Verbose logging
```

### Kafka Monitoring
```bash
# List topics
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092

# Check consumer lag
docker exec kafka-1 kafka-consumer-groups --bootstrap-server localhost:9092 --describe --all-groups
```

---

## Performance Optimizations

### Iceberg Optimizations
- **Snappy Compression**: Fast compression with good ratio
- **Partitioning**: Reduces data scanned for queries
- **Metadata Caching**: Fast query planning
- **File Compaction**: Merge small files periodically

### Spark Optimizations
- **Local Mode**: Simplified for development
- **Broadcast Joins**: For small reference tables (hotels)
- **Predicate Pushdown**: Filter at storage layer
- **Partition Pruning**: Skip irrelevant partitions

### DBT Optimizations
- **Incremental Models**: Only process new data
- **Merge Strategy**: Efficient upserts
- **Parallel Execution**: Run independent models concurrently

---

## Troubleshooting

### Issue: Kafka Connection Failed
```bash
# Check Kafka brokers
docker ps | grep kafka

# Verify listeners
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server localhost:9092
```

### Issue: HDFS Connection Failed
```bash
# Check NameNode
docker exec namenode hdfs dfsadmin -report

# Test connectivity
docker exec namenode hdfs dfs -ls /
```

### Issue: DBT Run Failed
```bash
# Check DBT debug
cd dbt/
dbt debug --profiles-dir . --profile snapptrip --target local

# Check Spark session
# Ensure Spark session is running in notebook
```

### Issue: PostgreSQL Connection Failed
```bash
# Check PostgreSQL
docker exec postgres psql -U airflow -d gold_layer -c "\dt gold.*"
```

---

## Future Enhancements

1. **Airflow DAGs**: Orchestrate entire pipeline
2. **Streaming**: Real-time processing with Spark Structured Streaming
3. **Data Catalog**: Integrate with Apache Atlas or AWS Glue
4. **Monitoring**: Add Prometheus + Grafana dashboards
5. **CI/CD**: Automated testing and deployment
6. **Data Versioning**: Implement data version control with DVC
7. **ML Integration**: Feature store for ML models

---

## References

- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [DBT Documentation](https://docs.getdbt.com/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [HDFS Documentation](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html)
