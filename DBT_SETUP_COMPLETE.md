# ✅ DBT Pipeline Setup Complete!

## What's Been Configured

### 1. DBT Models Created

#### Silver Layer: `models/silver/silver_booking_state.sql`
- **Input**: `local.bronze.bookings_raw` (Iceberg)
- **Output**: `local.silver.silver_booking_state` (Iceberg)
- **Transformations**:
  - Deduplicates by `booking_id` (latest `updated_at`)
  - Enriches with hotel data (adds `city`, `star_rating`)
  - Applies business rules (price > 0, valid status)
  - Filters invalid records
- **Format**: Iceberg, partitioned by `date(created_at)`
- **Strategy**: Incremental merge

#### Gold Layer: `models/gold/gold_daily_kpis_v2.sql`
- **Input**: `local.silver.silver_booking_state` (from DBT ref)
- **Output**: `local.gold.gold_daily_kpis_v2` (Iceberg)
- **Metrics**: Daily KPIs by city (bookings, revenue, cancellation rate, etc.)
- **Format**: Iceberg, partitioned by `booking_date`
- **Strategy**: Incremental merge

### 2. Data Quality Tests

#### Silver Layer Tests (`models/silver/schema.yml`):
- ✅ `booking_id`: unique, not_null
- ✅ `user_id`, `hotel_id`: not_null
- ✅ `status`: accepted_values ('created', 'confirmed', 'cancelled')
- ✅ `price`: not_null, > 0
- ✅ `city`: not_null (after enrichment)
- ✅ `hotel_id`: relationships to reference.hotels
- ✅ `created_at <= updated_at`: logical timestamp check
- ✅ `star_rating`: between 1 and 5

#### Gold Layer Tests (`models/gold/schema_v2.yml`):
- ✅ Unique combination of (`booking_date`, `city`)
- ✅ `total_revenue >= 0`
- ✅ `cancellation_rate`: between 0 and 100
- ✅ Consistency: `confirmed + cancelled + pending = total`
- ✅ Logic: `confirmed_bookings <= total_bookings`
- ✅ No future dates

### 3. DBT Packages Installed

✅ `dbt-utils` (v1.1.1) - Advanced testing and macros
✅ `dbt-expectations` (v0.10.1) - Great Expectations-style tests
✅ `dbt-codegen` (v0.12.1) - Code generation utilities
✅ `dbt-date` (v0.10.1) - Date manipulation macros

### 4. Lineage Tracking

DBT automatically tracks:
- **Source → Model dependencies**
- **Model → Model dependencies**
- **Column-level lineage**
- **Test coverage**

View with: `dbt docs serve --port 8001`

### 5. Integration with Notebooks

New notebook created: `06_dbt_pipeline.ipynb`

This notebook:
1. Installs DBT dependencies
2. Runs Silver layer models
3. Tests Silver data quality
4. Runs Gold layer models
5. Tests Gold data quality
6. Generates lineage documentation
7. Verifies results with Spark

## How to Use

### Quick Start

```bash
# 1. Start Docker services
make docker-up

# 2. Open Jupyter
jupyter lab notebooks/

# 3. Run notebooks in order:
#    - 01_kafka_service.ipynb (produce data)
#    - 02_bronze_layer.ipynb (ingest to Bronze + create hotels reference)
#    - 06_dbt_pipeline.ipynb (DBT: Bronze → Silver → Gold with tests)
```

### View Lineage

```bash
cd dbt
dbt docs generate --target local
dbt docs serve --port 8001
```

Open http://localhost:8001 and click the blue graph icon (bottom right).

### Run DBT from Command Line

```bash
cd dbt

# Run entire pipeline
dbt build --target local

# Run specific layer
dbt run --select tag:silver --target local
dbt run --select tag:gold --target local

# Run tests only
dbt test --target local

# Run incrementally (only new data)
dbt run --select tag:silver+ --target local
```

## Pipeline Flow

```
Kafka (Raw Events)
  ↓
[Notebook 02: Bronze Layer]
  ↓
local.bronze.bookings_raw (Iceberg in /tmp/lakehouse or HDFS)
  ↓
[DBT: Silver Layer Model]
  ├─ Deduplicate
  ├─ Enrich with hotels (city)
  ├─ Apply business rules
  └─ Data quality tests (8 tests)
  ↓
local.silver.silver_booking_state (Iceberg)
  ↓
[DBT: Gold Layer Model]
  ├─ Aggregate by date + city
  ├─ Calculate KPIs
  └─ Data quality tests (6 tests)
  ↓
local.gold.gold_daily_kpis_v2 (Iceberg)
```

## Data Storage

### Development (target: local)
- **Location**: `/tmp/lakehouse`
- **Bronze**: `/tmp/lakehouse/bronze/bookings_raw`
- **Reference**: `/tmp/lakehouse/reference/hotels`
- **Silver**: `/tmp/lakehouse/silver/silver_booking_state`
- **Gold**: `/tmp/lakehouse/gold/gold_daily_kpis_v2`

### Production (target: dev)
- **Location**: `hdfs://namenode:9000/lakehouse`
- **Bronze**: `hdfs://namenode:9000/lakehouse/bronze/bookings_raw`
- **Reference**: `hdfs://namenode:9000/lakehouse/reference/hotels`
- **Silver**: `hdfs://namenode:9000/lakehouse/silver/silver_booking_state`
- **Gold**: `hdfs://namenode:9000/lakehouse/gold/gold_daily_kpis_v2`

## Key Features

### 1. All Layers in Iceberg Format
- ✅ Bronze, Silver, Gold all use Iceberg
- ✅ Time travel capabilities
- ✅ Schema evolution
- ✅ ACID transactions

### 2. Data Quality at Every Layer
- ✅ 8 tests on Silver layer
- ✅ 6 tests on Gold layer
- ✅ Automatic test execution
- ✅ Test failure tracking

### 3. Lineage Tracking
- ✅ Automatic dependency graph
- ✅ Column-level lineage
- ✅ Visual documentation
- ✅ Impact analysis

### 4. Incremental Processing
- ✅ Only processes new/updated records
- ✅ Efficient for large datasets
- ✅ Merge strategy for upserts
- ✅ Full refresh option available

## Troubleshooting

### Issue: "Table local.bronze.bookings_raw not found"
**Solution**: Run notebook 02 first to create Bronze layer

### Issue: "Table local.reference.hotels not found"
**Solution**: Run notebook 02, Cell 12 (new cell) to create hotels reference table

### Issue: DBT tests failing
**Solution**: Check test results:
```bash
cd dbt
dbt test --target local --store-failures
cat target/run_results.json
```

### Issue: Want to use HDFS instead of /tmp
**Solution**: Change target from `local` to `dev`:
```bash
dbt run --target dev
```

## Next Steps

1. ✅ **Run Bronze Layer**: Execute notebook 02 (including new Cell 12 for hotels)
2. ✅ **Run DBT Pipeline**: Execute notebook 06
3. ✅ **View Lineage**: `dbt docs serve --port 8001`
4. ✅ **Schedule with Airflow**: Create DAG to run `dbt build --target dev`

## Summary

You now have a production-ready DBT pipeline with:
- ✅ All layers persisted in Iceberg format (HDFS-ready)
- ✅ Comprehensive data quality checks (14 tests total)
- ✅ Automatic lineage tracking and documentation
- ✅ Incremental processing for efficiency
- ✅ Integrated with Jupyter notebooks
- ✅ SQL-based transformations (easy to maintain)

**Ready to run!** Open `06_dbt_pipeline.ipynb` and execute all cells.
