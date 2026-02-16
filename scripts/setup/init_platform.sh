#!/bin/bash

# SnappTrip Data Platform - Initialization Script

echo "Initializing SnappTrip Data Platform..."

# 1. Initialize HDFS
echo "Initializing HDFS..."
bash scripts/setup/init_hdfs.sh

# 2. Initialize Kafka Topics
echo "Initializing Kafka Topics..."
bash scripts/setup/init_kafka_topics.sh

# 3. Initialize PostgreSQL (handled by init container, but verify)
echo "Checking PostgreSQL..."
docker exec postgres psql -U airflow -d gold_layer -c "SELECT count(*) FROM gold.daily_kpis;" || echo "Gold tables not ready yet"

# 4. Generate Sample Data
echo "Generating Sample Data..."
# We run this inside the spark-master container to ensure dependencies are present
docker exec spark-master python3 /opt/spark/jobs/ingestion/data_generator.py

echo "Initialization Complete!"
