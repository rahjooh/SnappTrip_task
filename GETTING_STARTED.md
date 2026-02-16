# SnappTrip Data Platform - Getting Started

## Quick Start

### 1. Start Docker Services
```bash
make docker-up
```

### 2. Run Notebooks in Order

Open Jupyter and run these notebooks sequentially:

```bash
jupyter lab notebooks/
```

**Order matters!** Each notebook depends on the previous one.

#### Option A: PySpark Pipeline (Original)

1. **01_kafka_service.ipynb** - Produces booking data to Kafka
2. **02_bronze_layer.ipynb** - Ingests from Kafka to Iceberg Bronze layer
3. **03_silver_layer.ipynb** - Transforms Bronze to Silver layer (includes city enrichment)
4. **04_gold_layer.ipynb** - Calculates KPIs and writes to PostgreSQL

#### Option B: DBT Pipeline (Recommended) ⭐

1. **01_kafka_service.ipynb** - Produces booking data to Kafka
2. **02_bronze_layer.ipynb** - Ingests from Kafka to Iceberg Bronze layer
3. **06_dbt_pipeline.ipynb** - DBT transforms Bronze → Silver → Gold with data quality checks and lineage

**DBT Pipeline Benefits**:
- ✅ All layers in HDFS Iceberg format
- ✅ Automated data quality testing
- ✅ Lineage tracking and documentation
- ✅ Incremental processing
- ✅ SQL-based transformations

### 3. Verify Results

```bash
# Check Silver table has data with city
docker exec spark-master spark-submit --class org.apache.spark.examples.SparkPi /opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar

# Or query PostgreSQL
docker exec -it postgres psql -U airflow -d gold_layer -c "SELECT * FROM gold_daily_kpis LIMIT 5;"
```

## Key Configuration Changes

- **Iceberg Warehouse**: `/tmp/lakehouse` (local filesystem instead of HDFS)
- **Spark Master**: `local[*]` in notebooks
- **Kafka Bootstrap**: `localhost:19092`
- **PostgreSQL**: `localhost:5432` (user: `airflow`, password: `airflow`)

## Troubleshooting

### Issue: Silver table missing `city` column
- Solution: Make sure Cell 14 in `03_silver_layer.ipynb` joins with hotels data

### Issue: Gold Layer fails to find Silver table
- Solution: Re-run Silver notebook after deleting `/tmp/lakehouse/silver`

### Issue: Java version conflicts
- Solution: Python notebooks set `JAVA_HOME` to Java 17 (Temurin JDK)

## Architecture

```
Kafka (localhost:19092)
  ↓
Bronze Layer (/tmp/lakehouse/bronze)
  ↓
Silver Layer (/tmp/lakehouse/silver) - includes city enrichment
  ↓
Gold Layer (PostgreSQL) - KPIs by city and date
```

## Files Modified

- `notebooks/02_bronze_layer.ipynb` - Uses local Spark mode
- `notebooks/03_silver_layer.ipynb` - Cell 14 enriches with hotel city data
- `notebooks/04_gold_layer.ipynb` - Reads from Silver, groups by city
- `docker/hadoop/Dockerfile` - ARM64 compatible base image
- `docker/spark/Dockerfile` - Apache Spark official image
- `docker/trino/config.properties` - Updated catalog configuration

## Next Steps

1. Run notebooks 01-04 in order
2. Verify data in PostgreSQL
3. Check visualizations in Gold Layer notebook
