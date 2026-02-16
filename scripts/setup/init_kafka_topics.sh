#!/bin/bash

# Initialize Kafka Topics for SnappTrip Data Platform

set -e

echo "Initializing Kafka topics..."

KAFKA_BROKER="kafka-1:9092"

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
sleep 30

# Create bookings.raw topic
echo "Creating bookings.raw topic..."
docker exec kafka-1 kafka-topics --create \
    --bootstrap-server $KAFKA_BROKER \
    --topic bookings.raw \
    --partitions 12 \
    --replication-factor 3 \
    --config compression.type=snappy \
    --config retention.ms=604800000 \
    --if-not-exists

# Create booking_events.raw topic
echo "Creating booking_events.raw topic..."
docker exec kafka-1 kafka-topics --create \
    --bootstrap-server $KAFKA_BROKER \
    --topic booking_events.raw \
    --partitions 12 \
    --replication-factor 3 \
    --config compression.type=snappy \
    --config retention.ms=604800000 \
    --if-not-exists

# Create hotels.raw topic
echo "Creating hotels.raw topic..."
docker exec kafka-1 kafka-topics --create \
    --bootstrap-server $KAFKA_BROKER \
    --topic hotels.raw \
    --partitions 3 \
    --replication-factor 3 \
    --config compression.type=snappy \
    --config retention.ms=2592000000 \
    --if-not-exists

# List all topics
echo "Listing all topics..."
docker exec kafka-1 kafka-topics --list --bootstrap-server $KAFKA_BROKER

echo "Kafka topics initialized successfully!"
