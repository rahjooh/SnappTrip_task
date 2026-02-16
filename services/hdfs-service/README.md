# HDFS Service

## Overview

Hadoop Distributed File System for storing Bronze and Silver layer data in Iceberg format.

## Components

- **NameNode**: HDFS master node
- **DataNode** (x2): HDFS worker nodes
- **Iceberg**: Table format for lakehouse

## Quick Start

```bash
# Start HDFS service
make up

# Check status
make status

# View logs
make logs

# Stop service
make down
```

## Configuration

- **NameNode UI**: http://localhost:9870
- **NameNode RPC**: localhost:9000
- **Replication Factor**: 2
- **Block Size**: 128MB

## Testing

```bash
# Test HDFS
make test

# List files
make ls

# Create directory
make mkdir DIR=/test

# Upload file
make put LOCAL=/path/to/file REMOTE=/hdfs/path
```

## Storage Structure

```
/lakehouse/
├── bronze/
│   ├── bookings_raw/
│   ├── booking_events_raw/
│   └── hotels_raw/
└── silver/
    └── booking_state/
```

## Monitoring

- NameNode UI: http://localhost:9870
- Metrics: http://localhost:9870/jmx
