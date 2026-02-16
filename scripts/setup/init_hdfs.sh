#!/bin/bash

# Initialize HDFS directories for SnappTrip Data Platform

set -e

echo "Initializing HDFS directories..."

# Wait for HDFS to be ready
echo "Waiting for HDFS to be ready..."
sleep 30

# Create warehouse directory
echo "Creating warehouse directory..."
docker exec namenode hdfs dfs -mkdir -p /warehouse/bronze
docker exec namenode hdfs dfs -mkdir -p /warehouse/silver
docker exec namenode hdfs dfs -mkdir -p /warehouse/gold

# Create checkpoint directory
echo "Creating checkpoint directory..."
docker exec namenode hdfs dfs -mkdir -p /checkpoints

# Create Spark logs directory
echo "Creating Spark logs directory..."
docker exec namenode hdfs dfs -mkdir -p /spark-logs

# Set permissions
echo "Setting permissions..."
docker exec namenode hdfs dfs -chmod -R 777 /warehouse
docker exec namenode hdfs dfs -chmod -R 777 /checkpoints
docker exec namenode hdfs dfs -chmod -R 777 /spark-logs

# List directories
echo "Listing HDFS directories..."
docker exec namenode hdfs dfs -ls /

echo "HDFS directories initialized successfully!"
