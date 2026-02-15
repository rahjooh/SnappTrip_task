#!/bin/bash
# Setup DBT pipeline with Iceberg + HDFS + Data Quality + Lineage

set -e

echo "========================================================================"
echo "Setting up DBT Pipeline for SnappTrip Data Platform"
echo "========================================================================"

# Change to DBT directory
cd "$(dirname "$0")/dbt"

echo ""
echo "[1/4] Installing DBT dependencies (dbt-utils, dbt-expectations)..."
dbt deps

echo ""
echo "[2/4] Testing DBT connection to Spark..."
dbt debug --target local

echo ""
echo "[3/4] Compiling DBT models..."
dbt compile --target local

echo ""
echo "[4/4] Generating documentation and lineage..."
dbt docs generate --target local

echo ""
echo "========================================================================"
echo "✅ DBT Pipeline Setup Complete!"
echo "========================================================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. Run Bronze Layer notebook (02_bronze_layer.ipynb) to create:"
echo "   - local.bronze.bookings_raw (from Kafka)"
echo "   - local.reference.hotels (from CSV)"
echo ""
echo "2. Run DBT Pipeline notebook (06_dbt_pipeline.ipynb) to:"
echo "   - Transform Bronze → Silver (with deduplication + enrichment)"
echo "   - Transform Silver → Gold (with KPI aggregations)"
echo "   - Run data quality tests"
echo "   - Generate lineage documentation"
echo ""
echo "3. View lineage graph:"
echo "   cd dbt && dbt docs serve --port 8001"
echo "   Open: http://localhost:8001"
echo ""
echo "========================================================================"
