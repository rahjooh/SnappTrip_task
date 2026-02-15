#!/bin/bash

# Initialize Kafka Topics for SnappTrip Data Platform

set -e

echo "Initializing Kafka topics..."

KAFKA_BROKER="kafka-1:9092"

# Wait for Kafka to accept topic commands (retry until ready)
echo "Waiting for Kafka to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if docker exec kafka-1 kafka-topics --list --bootstrap-server "$KAFKA_BROKER" &>/dev/null; then
    echo "Kafka is ready."
    break
  fi
  if [ "$i" -eq 12 ]; then
    echo "ERROR: Kafka did not become ready in time. Run 'make restart' and try again."
    exit 1
  fi
  echo "  attempt $i/12: waiting 5s..."
  sleep 5
done

# Create bookings_raw topic (used by notebook 01 and bronze layer)
echo "Creating bookings_raw topic..."
docker exec kafka-1 kafka-topics --create \
    --bootstrap-server $KAFKA_BROKER \
    --topic bookings_raw \
    --partitions 3 \
    --replication-factor 2 \
    --config compression.type=snappy \
    --config retention.ms=604800000 \
    --if-not-exists

# Create booking_events_raw topic
echo "Creating booking_events_raw topic..."
docker exec kafka-1 kafka-topics --create \
    --bootstrap-server $KAFKA_BROKER \
    --topic booking_events_raw \
    --partitions 3 \
    --replication-factor 2 \
    --config compression.type=snappy \
    --config retention.ms=604800000 \
    --if-not-exists

# Create hotels_raw topic
echo "Creating hotels_raw topic..."
docker exec kafka-1 kafka-topics --create \
    --bootstrap-server $KAFKA_BROKER \
    --topic hotels_raw \
    --partitions 3 \
    --replication-factor 2 \
    --config compression.type=snappy \
    --config retention.ms=2592000000 \
    --if-not-exists

# List all topics
echo "Listing all topics..."
docker exec kafka-1 kafka-topics --list --bootstrap-server $KAFKA_BROKER

echo "Kafka topics initialized successfully!"
