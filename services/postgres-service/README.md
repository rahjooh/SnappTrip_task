# PostgreSQL Service

## Overview

PostgreSQL database for Gold layer analytics tables.

## Quick Start

```bash
# Start PostgreSQL
make up

# Check status
make status

# Connect to database
make connect

# Stop service
make down
```

## Configuration

- **Host**: localhost
- **Port**: 5432
- **Database**: snapptrip_analytics
- **User**: snapptrip
- **Password**: snapptrip123

## Connection String

```
postgresql://snapptrip:snapptrip123@localhost:5432/snapptrip_analytics
```

## Testing

```bash
# Test connection
make test

# Run sample query
make query SQL="SELECT * FROM gold_daily_kpis LIMIT 10"
```

## Backup & Restore

```bash
# Backup database
make backup

# Restore database
make restore FILE=backup.sql
```
