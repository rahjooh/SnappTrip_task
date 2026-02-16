# Kafka Service

## Overview

Apache Kafka message broker with Schema Registry for the SnappTrip Data Platform.

## Components

- **Kafka Broker**: Message streaming platform
- **Zookeeper**: Kafka coordination service
- **Schema Registry**: Avro schema management
- **Kafka UI**: Web interface for monitoring

## Topics

- `bookings_raw`: Raw booking data (CDC)
- `booking_events_raw`: Booking event stream
- `hotels_raw`: Hotel reference data

## Quick Start

```bash
# Start Kafka service
make up

# Check status
make status

# View logs
make logs

# Stop service
make down
```

## Configuration

- **Broker Port**: 9092
- **Schema Registry Port**: 8081
- **Kafka UI Port**: 8080
- **Retention**: 7 days

## Testing

```bash
# Test producer
make test-producer

# Test consumer
make test-consumer

# List topics
make list-topics
```

## Schemas

All Avro schemas are in `schemas/` directory:
- `booking.avsc`
- `booking_event.avsc`
- `hotel.avsc`
