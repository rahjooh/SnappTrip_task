# DBT Pipeline Guide - Iceberg + HDFS + Data Quality + Lineage

## Overview

This guide shows how to use DBT to manage the entire data pipeline with:
- ✅ **All layers in HDFS Iceberg format** (Bronze → Silver → Gold)
- ✅ **Data quality checks** at each layer
- ✅ **Lineage tracking** and documentation
- ✅ **Incremental processing** for efficiency
- ✅ **Integrated with Jupyter notebooks**

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kafka (Raw Events)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Bronze Layer (Notebook 02)                                  │
│  - Kafka → Iceberg (HDFS)                                    │
│  - Raw, unprocessed data                                     │
│  - Location: hdfs://namenode:9000/lakehouse/bronze          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Silver Layer (DBT Model)                                    │
│  - Deduplication (latest record per booking_id)              │
│  - Enrichment (join with hotels for city)                   │
│  - Business rules (price > 0, valid status)                 │
│  - Data quality tests (not_null, unique, relationships)     │
│  - Location: hdfs://namenode:9000/lakehouse/silver          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Gold Layer (DBT Model)                                      │
│  - Daily KPIs by city                                        │
│  - Aggregations (counts, revenue, rates)                    │
│  - Data quality tests (consistency, logic checks)           │
│  - Location: hdfs://namenode:9000/lakehouse/gold            │
└─────────────────────────────────────────────────────────────┘
```

## Setup

### 1. Install DBT and Dependencies

```bash
# Install dbt-spark
pip install dbt-spark

# Install DBT packages (dbt-utils, dbt-expectations)
cd dbt
dbt deps
```

### 2. Configure DBT Profile

The `dbt/profiles.yml` is already configured with three targets:

- **`local`**: For notebook development (uses `/tmp/lakehouse`)
- **`dev`**: For Docker Spark cluster (uses `hdfs://namenode:9000/lakehouse`)
- **`prod`**: For PostgreSQL (final Gold layer export)

## DBT Models Created

### Silver Layer: `silver_booking_state.sql`

**Purpose**: Clean, deduplicated, enriched booking data

**Transformations**:
1. Deduplicates bookings (latest `updated_at` per `booking_id`)
2. Joins with hotels to add `city` and `star_rating`
3. Applies business rules:
   - `price > 0`
   - `status IN ('created', 'confirmed', 'cancelled')`
   - `created_at <= updated_at`
4. Filters out null required fields

**Data Quality Tests**:
- `booking_id`: unique, not_null
- `status`: accepted_values
- `price`: not_null, > 0
- `city`: not_null (after enrichment)
- `hotel_id`: relationships to hotels table
- Model-level: `created_at <= updated_at`

**Configuration**:
```sql
materialized='incremental'
file_format='iceberg'
unique_key='booking_id'
incremental_strategy='merge'
partition_by=['date(created_at)']
```

### Gold Layer: `gold_daily_kpis_v2.sql`

**Purpose**: Daily KPI aggregations by city

**Metrics**:
- `total_bookings`, `confirmed_bookings`, `cancelled_bookings`, `pending_bookings`
- `cancellation_rate` (%)
- `total_revenue` (only confirmed bookings)
- `avg_booking_price`, `avg_confirmed_price`
- `min_price`, `max_price`
- `avg_star_rating`
- `unique_customers`

**Data Quality Tests**:
- Unique combination of (`booking_date`, `city`)
- `total_revenue >= 0`
- `cancellation_rate BETWEEN 0 AND 100`
- Consistency: `confirmed + cancelled + pending = total`
- Logic: `confirmed_bookings <= total_bookings`
- No future dates

**Configuration**:
```sql
materialized='incremental'
file_format='iceberg'
unique_key=['booking_date', 'city']
incremental_strategy='merge'
partition_by=['booking_date']
```

## Usage

### Option 1: Run via Notebook (Recommended)

Open `notebooks/06_dbt_pipeline.ipynb` and run all cells:

1. **Install dependencies**: `dbt deps`
2. **Debug connection**: `dbt debug`
3. **Run Silver layer**: `dbt run --select tag:silver`
4. **Test Silver layer**: `dbt test --select tag:silver`
5. **Run Gold layer**: `dbt run --select tag:gold`
6. **Test Gold layer**: `dbt test --select tag:gold`
7. **Generate docs**: `dbt docs generate`
8. **Verify with Spark**: Read Iceberg tables

### Option 2: Run via Command Line

```bash
cd dbt

# Run entire pipeline
dbt run --target local

# Run with tests
dbt build --target local

# Run specific layer
dbt run --select tag:silver --target local
dbt run --select tag:gold --target local

# Run tests only
dbt test --target local

# Generate documentation
dbt docs generate --target local
dbt docs serve --port 8001
```

### Option 3: Run Incrementally

```bash
# Only process new data (incremental mode)
dbt run --select tag:silver+ --target local

# Full refresh (reprocess all data)
dbt run --select tag:silver --full-refresh --target local
```

## Data Quality Checks

### Silver Layer Tests

| Test | Description | Severity |
|------|-------------|----------|
| `unique(booking_id)` | No duplicate bookings | error |
| `not_null(booking_id, user_id, hotel_id)` | Required fields | error |
| `accepted_values(status)` | Valid status values | error |
| `price > 0` | Positive prices | error |
| `relationships(hotel_id)` | Valid hotel references | error |
| `created_at <= updated_at` | Logical timestamps | error |
| `city not_null` | Enrichment successful | error |

### Gold Layer Tests

| Test | Description | Severity |
|------|-------------|----------|
| `unique(booking_date, city)` | No duplicate aggregates | error |
| `total_revenue >= 0` | Non-negative revenue | error |
| `cancellation_rate 0-100` | Valid percentage | warn |
| `confirmed + cancelled + pending = total` | Consistency | error |
| `confirmed <= total` | Logical check | error |
| `booking_date <= today` | No future dates | warn |

## Lineage Tracking

### View Lineage Graph

```bash
cd dbt
dbt docs generate --target local
dbt docs serve --port 8001
```

Open http://localhost:8001 and click the blue icon (bottom right) to see the lineage graph.

### Lineage Flow

```
source('bronze', 'bookings_raw')
  ↓
ref('silver_booking_state')
  ↓
ref('gold_daily_kpis_v2')
```

### Extract Lineage Programmatically

The notebook (Cell 8) parses `target/manifest.json` to show dependencies:

```python
manifest = json.load(open('target/manifest.json'))
for node in manifest['nodes']:
    print(f"{node['name']} depends on {node['depends_on']}")
```

## Integration with Existing Notebooks

### Current Pipeline (Notebooks 01-04)

1. **01_kafka_service.ipynb**: Produce data to Kafka
2. **02_bronze_layer.ipynb**: Kafka → Iceberg Bronze
3. **03_silver_layer.ipynb**: Bronze → Silver (PySpark)
4. **04_gold_layer.ipynb**: Silver → Gold (PySpark)

### New DBT Pipeline (Notebook 06)

1. **01_kafka_service.ipynb**: Produce data to Kafka
2. **02_bronze_layer.ipynb**: Kafka → Iceberg Bronze
3. **06_dbt_pipeline.ipynb**: Bronze → Silver → Gold (DBT)

**Advantages of DBT approach**:
- ✅ SQL-based (easier to maintain)
- ✅ Built-in data quality testing
- ✅ Automatic lineage tracking
- ✅ Incremental processing
- ✅ Documentation generation
- ✅ Version control friendly

## Troubleshooting

### Issue: DBT can't connect to Spark

**Solution**: Make sure Spark Thrift server is running:
```bash
docker exec spark-master /opt/spark/sbin/start-thriftserver.sh
```

### Issue: Iceberg tables not found

**Solution**: Ensure Bronze layer notebook (02) has run first to create the source tables.

### Issue: Tests failing

**Solution**: Check test results:
```bash
dbt test --target local --store-failures
```

View failures in `target/run_results.json`

### Issue: Incremental not working

**Solution**: Run full refresh:
```bash
dbt run --select model_name --full-refresh --target local
```

## Next Steps

1. **Run the pipeline**: Open `06_dbt_pipeline.ipynb` and execute all cells
2. **View lineage**: `dbt docs serve --port 8001`
3. **Schedule with Airflow**: Create DAG to run `dbt run --target dev`
4. **Add more tests**: Extend `schema.yml` files with custom tests
5. **Export to PostgreSQL**: Run `dbt run --target prod` to export Gold to Postgres

## Summary

You now have a complete DBT pipeline that:
- ✅ Reads from Bronze Iceberg tables (HDFS)
- ✅ Transforms to Silver with deduplication and enrichment
- ✅ Aggregates to Gold with KPIs
- ✅ Stores all layers in Iceberg format
- ✅ Includes comprehensive data quality tests
- ✅ Tracks lineage automatically
- ✅ Runs incrementally for efficiency
- ✅ Integrates with Jupyter notebooks
