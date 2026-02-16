# Getting Started - SnappTrip Data Platform

## Quick Start (5 Minutes)

### 1. Setup Environment
```bash
cd snapptrip-data-platform
./scripts/dev/setup_environment.sh
```

### 2. Activate Environment
```bash
conda activate snapptrip
```

### 3. Verify Installation
```bash
python verify_setup.py
```

### 4. Run Tests
```bash
pytest tests/unit/ -v
```

---

## What You Get

### Data Platform Components
- **Bronze Layer**: Raw data ingestion from Kafka → Iceberg
- **Silver Layer**: State reconciliation with late-data handling
- **Gold Layer**: Aggregated KPIs in PostgreSQL

### Technologies
- Apache Spark 3.5 + PySpark
- Apache Kafka + Schema Registry
- Apache Iceberg (lakehouse format)
- Apache Airflow 2.7.2
- dbt-spark
- Trino 435
- PostgreSQL 15
- Prometheus + Grafana

### Development Tools
- Python 3.11 (via conda)
- pytest + chispa (testing)
- Great Expectations (data quality)
- black + flake8 + mypy (code quality)

---

## Project Structure

```
snapptrip-data-platform/
├── src/                    # Python source code
│   ├── bronze/            # Streaming ingestion
│   ├── silver/            # State reconciliation
│   ├── gold/              # Aggregations
│   ├── ingestion/         # Data generators & Kafka producers
│   └── common/            # Shared utilities
├── dbt/                   # dbt models & tests
├── airflow/               # Airflow DAGs
├── docker/                # Docker configurations
│   ├── hadoop/           # HDFS cluster
│   ├── spark/            # Spark cluster
│   ├── kafka/            # Kafka + Schema Registry
│   ├── airflow/          # Airflow scheduler + workers
│   └── monitoring/       # Prometheus + Grafana
├── tests/                 # Unit, integration, performance tests
├── scripts/               # Setup & maintenance scripts
│   ├── dev/              # Development scripts
│   └── setup/            # Infrastructure setup
├── docs/                  # Documentation
│   ├── setup/            # Setup guides
│   ├── architecture/     # Architecture docs
│   └── operations/       # Runbooks
└── great_expectations/    # Data quality suites
```

---

## Available Commands

### Environment Setup
```bash
# Create conda environment
./scripts/dev/setup_environment.sh

# Activate environment
conda activate snapptrip

# Verify setup
python verify_setup.py
```

### Development
```bash
# Run tests
make test                  # All tests
make test-unit            # Unit tests only
make test-integration     # Integration tests

# Code quality
make format               # Format with black & isort
make lint                 # Run flake8 & mypy
make clean                # Clean artifacts
```

### Docker Operations
```bash
# Start all services
make docker-up

# Stop services
make docker-down

# View logs
make docker-logs

# Initialize infrastructure
make init-infra

# Load sample data
make init-data
```

### dbt Operations
```bash
# Run dbt models
make dbt-run

# Run dbt tests
make dbt-test

# Generate docs
make dbt-docs
```

---

## Access Services (After Docker Start)

| Service | URL | Credentials |
|---------|-----|-------------|
| Airflow | http://localhost:8090 | admin/admin |
| Grafana | http://localhost:3000 | admin/admin |
| Spark Master | http://localhost:8082 | - |
| Trino | http://localhost:8081 | - |
| Prometheus | http://localhost:9090 | - |
| JupyterHub | http://localhost:8888 | - |

---

## Next Steps

### Option 1: Review Code (Fastest)
```bash
# Read implementation summary
cat IMPLEMENTATION_SUMMARY.md

# Review Silver layer logic
cat src/silver/booking_state_reconciliation.py

# Review Gold layer SQL
cat dbt/models/gold/gold_daily_kpis.sql
```

### Option 2: Run Tests
```bash
conda activate snapptrip
pytest tests/unit/ -v
pytest tests/unit/test_silver_reconciliation.py -v
```

### Option 3: Start Full Platform
```bash
# Ensure Docker is running
docker ps

# Start all services
make docker-up

# Wait 2-3 minutes, then initialize
make init-infra
make init-data
```

---

## Troubleshooting

### Conda Issues
```bash
# Initialize conda
source ~/miniconda3/etc/profile.d/conda.sh

# Recreate environment
conda deactivate
conda env remove -n snapptrip
./scripts/dev/setup_environment.sh
```

### Docker Issues
```bash
# Check Docker is running
docker ps

# Restart services
make docker-down
make docker-up
```

### Import Errors
```bash
conda activate snapptrip
pip install -e .
python verify_setup.py
```

---

## Key Files to Review

### Documentation
1. `IMPLEMENTATION_SUMMARY.md` - Technical implementation
2. `PROJECT_DELIVERY.md` - Complete delivery guide
3. `docs/architecture/` - Architecture diagrams
4. `docs/setup/GETTING_STARTED.md` - This file

### Source Code
1. `src/silver/booking_state_reconciliation.py` - Silver layer
2. `dbt/models/gold/gold_daily_kpis.sql` - Gold layer
3. `airflow/dags/medallion_pipeline_dag.py` - Orchestration
4. `tests/unit/test_silver_reconciliation.py` - Tests

---

## Success Checklist

- [ ] Conda environment created
- [ ] All packages installed
- [ ] `python verify_setup.py` passes
- [ ] Unit tests run successfully
- [ ] Reviewed Silver layer logic
- [ ] Reviewed Gold layer metrics
- [ ] Understood architecture
- [ ] Ready for interview

---

## Need Help?

- **Setup Issues**: See `docs/setup/TROUBLESHOOTING.md`
- **Architecture Questions**: See `docs/architecture/`
- **Operations**: See `docs/operations/runbooks/`
- **Quick Reference**: See `README.md`
