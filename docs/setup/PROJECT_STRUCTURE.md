# Project Structure

## 📁 Directory Organization

```
snapptrip-data-platform/
│
├── 📄 README.md                    # Main project overview
├── 📄 QUICKSTART.md                # 5-minute quick start guide
├── 📄 IMPLEMENTATION_SUMMARY.md    # Technical implementation details
├── 📄 PROJECT_DELIVERY.md          # Complete delivery documentation
├── 📄 REORGANIZATION_SUMMARY.md    # Project reorganization notes
├── 📄 Makefile                     # Build and development commands
├── 📄 verify_setup.py              # Environment verification script
├── 📄 .env.example                 # Environment variables template
├── 📄 requirements-core.txt        # Core Python dependencies
├── 📄 requirements-airflow.txt     # Airflow dependencies
├── 📄 requirements.txt             # All dependencies
├── 📄 setup.py                     # Python package setup
├── 📄 pytest.ini                   # Pytest configuration
│
├── 📂 src/                         # Python source code
│   ├── 📂 bronze/                 # Bronze layer (raw ingestion)
│   │   ├── streaming_ingestion.py
│   │   └── kafka_to_iceberg.py
│   ├── 📂 silver/                 # Silver layer (state reconciliation)
│   │   └── booking_state_reconciliation.py
│   ├── 📂 gold/                   # Gold layer (aggregations)
│   │   └── daily_kpis.py
│   ├── 📂 ingestion/              # Data generators & Kafka producers
│   │   ├── data_generator.py
│   │   ├── kafka_producer.py
│   │   └── schema_definitions.py
│   ├── 📂 common/                 # Shared utilities
│   │   ├── config.py
│   │   ├── spark_session.py
│   │   ├── iceberg_utils.py
│   │   ├── logging_config.py
│   │   └── metrics.py
│   └── 📂 utils/                  # Helper functions
│
├── 📂 dbt/                        # dbt models and tests
│   ├── 📂 models/
│   │   ├── 📂 bronze/            # Bronze layer models
│   │   ├── 📂 silver/            # Silver layer models
│   │   └── 📂 gold/              # Gold layer models & KPIs
│   │       ├── gold_daily_kpis.sql
│   │       └── schema.yml
│   ├── 📂 tests/                 # dbt data tests
│   ├── 📂 macros/                # dbt macros
│   ├── 📂 snapshots/             # dbt snapshots
│   └── dbt_project.yml
│
├── 📂 airflow/                    # Airflow DAGs and plugins
│   ├── 📂 dags/                  # Pipeline orchestration
│   │   ├── medallion_pipeline_dag.py
│   │   ├── bronze_ingestion_dag.py
│   │   ├── silver_reconciliation_dag.py
│   │   └── gold_aggregation_dag.py
│   ├── 📂 plugins/               # Custom operators & sensors
│   │   ├── operators/
│   │   └── sensors/
│   └── airflow.cfg
│
├── 📂 docker/                     # Docker configurations
│   ├── 📂 hadoop/                # HDFS cluster
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   ├── 📂 spark/                 # Spark cluster
│   │   ├── Dockerfile
│   │   └── spark-defaults.conf
│   ├── 📂 kafka/                 # Kafka + Schema Registry
│   │   └── Dockerfile
│   ├── 📂 airflow/               # Airflow scheduler + workers
│   │   └── Dockerfile
│   ├── 📂 trino/                 # Trino query engine
│   │   └── catalog/
│   ├── 📂 monitoring/            # Prometheus + Grafana
│   │   ├── prometheus/
│   │   └── grafana/
│   └── docker-compose.yml        # Main compose file
│
├── 📂 tests/                      # Comprehensive test suite
│   ├── 📂 unit/                  # Unit tests
│   │   ├── test_silver_reconciliation.py
│   │   ├── test_gold_aggregations.py
│   │   └── test_data_quality.py
│   ├── 📂 integration/           # Integration tests
│   │   ├── test_end_to_end.py
│   │   └── test_pipeline_flow.py
│   ├── 📂 performance/           # Performance benchmarks
│   │   └── test_spark_performance.py
│   └── conftest.py
│
├── 📂 scripts/                    # Setup & maintenance scripts
│   ├── 📂 dev/                   # Development tools
│   │   └── setup_environment.sh  # Unified environment setup
│   ├── 📂 setup/                 # Infrastructure initialization
│   │   ├── init_hdfs.sh
│   │   ├── init_kafka_topics.sh
│   │   ├── init_postgres.sh
│   │   ├── init_schema_registry.sh
│   │   └── init_platform.sh
│   ├── 📂 deployment/            # Deployment scripts
│   └── 📂 maintenance/           # Maintenance scripts
│
├── 📂 docs/                       # Documentation
│   ├── 📂 setup/                 # Setup guides
│   │   ├── GETTING_STARTED.md
│   │   ├── TROUBLESHOOTING.md
│   │   └── PROJECT_STRUCTURE.md  # This file
│   ├── 📂 architecture/          # Architecture documentation
│   │   ├── 01_system_overview.md
│   │   ├── 02_data_flow.md
│   │   ├── 03_silver_layer_design.md
│   │   ├── 04_gold_layer_design.md
│   │   └── diagrams/
│   ├── 📂 operations/            # Operations guides
│   │   └── runbooks/
│   │       ├── pipeline_failure.md
│   │       └── data_quality_issues.md
│   ├── 📂 development/           # Development guides
│   └── 📂 api/                   # API documentation
│
├── 📂 great_expectations/         # Data quality suites
│   ├── 📂 expectations/
│   ├── 📂 checkpoints/
│   └── great_expectations.yml
│
├── 📂 monitoring/                 # Monitoring configurations
│   ├── 📂 grafana/
│   │   └── dashboards/
│   ├── 📂 prometheus/
│   │   └── alerts/
│   └── 📂 loki/
│
├── 📂 ml/                         # ML platform (optional)
│   ├── 📂 kubeflow/
│   └── 📂 feast/
│
└── 📂 .github/                    # CI/CD workflows
    └── workflows/
        ├── test.yml
        └── deploy.yml
```

---

## 📋 Key Directories Explained

### Source Code (`src/`)
Contains all Python source code organized by data layer:
- **bronze/**: Raw data ingestion from Kafka to Iceberg
- **silver/**: State reconciliation with late-data handling
- **gold/**: Aggregations and KPIs
- **ingestion/**: Data generators and Kafka producers
- **common/**: Shared utilities (config, Spark session, logging)

### dbt (`dbt/`)
SQL-based transformations and tests:
- **models/**: SQL models for each layer
- **tests/**: Data quality tests
- **macros/**: Reusable SQL functions

### Airflow (`airflow/`)
Orchestration and scheduling:
- **dags/**: Pipeline definitions
- **plugins/**: Custom operators and sensors

### Docker (`docker/`)
Infrastructure as code:
- **hadoop/**: HDFS cluster configuration
- **spark/**: Spark cluster configuration
- **kafka/**: Kafka + Schema Registry
- **airflow/**: Airflow scheduler + workers
- **trino/**: Query engine
- **monitoring/**: Prometheus + Grafana

### Tests (`tests/`)
Comprehensive testing:
- **unit/**: Fast, isolated tests
- **integration/**: End-to-end pipeline tests
- **performance/**: Benchmark tests

### Scripts (`scripts/`)
Automation scripts:
- **dev/**: Development environment setup
- **setup/**: Infrastructure initialization
- **deployment/**: Deployment automation
- **maintenance/**: Maintenance tasks

### Documentation (`docs/`)
All project documentation:
- **setup/**: Getting started guides
- **architecture/**: System design docs
- **operations/**: Runbooks and troubleshooting
- **development/**: Development guides
- **api/**: API documentation

---

## 🎯 File Naming Conventions

### Python Files
- `snake_case.py` for all Python files
- `test_*.py` for test files
- `__init__.py` for package initialization

### Documentation
- `UPPERCASE.md` for root-level docs (README.md, QUICKSTART.md)
- `Title_Case.md` for nested docs (Getting_Started.md)
- `lowercase.md` for specific guides (troubleshooting.md)

### Scripts
- `snake_case.sh` for all bash scripts
- `init_*.sh` for initialization scripts
- `setup_*.sh` for setup scripts

### Configuration
- `.env` for environment variables
- `*.yml` or `*.yaml` for YAML configs
- `*.conf` for application configs
- `Dockerfile` for Docker images
- `docker-compose.yml` for Docker Compose

---

## 🔍 Finding Files

### By Purpose

**Setup & Installation:**
- `QUICKSTART.md`
- `scripts/dev/setup_environment.sh`
- `docs/setup/GETTING_STARTED.md`

**Architecture & Design:**
- `README.md`
- `IMPLEMENTATION_SUMMARY.md`
- `docs/architecture/`

**Troubleshooting:**
- `docs/setup/TROUBLESHOOTING.md`
- `docs/operations/runbooks/`

**Source Code:**
- Silver layer: `src/silver/booking_state_reconciliation.py`
- Gold layer: `dbt/models/gold/gold_daily_kpis.sql`
- Orchestration: `airflow/dags/medallion_pipeline_dag.py`

**Tests:**
- Unit tests: `tests/unit/`
- Integration tests: `tests/integration/`

**Docker:**
- Main compose: `docker/docker-compose.yml`
- Service configs: `docker/<service>/`

---

## 📊 File Count Summary

| Category | Count | Purpose |
|----------|-------|---------|
| Python files | 50+ | Source code & tests |
| SQL files | 20+ | dbt models & tests |
| Markdown files | 30+ | Documentation |
| Shell scripts | 15+ | Automation |
| YAML files | 25+ | Configuration |
| Dockerfiles | 10+ | Container images |

---

## 🎓 Navigation Tips

### For Reviewers
1. Start with `QUICKSTART.md`
2. Read `README.md` for overview
3. Check `IMPLEMENTATION_SUMMARY.md` for details
4. Review code in `src/` and `dbt/`

### For Developers
1. Setup: `scripts/dev/setup_environment.sh`
2. Tests: `tests/`
3. Source: `src/`, `dbt/`, `airflow/`
4. Docs: `docs/development/`

### For Operations
1. Docker: `docker/docker-compose.yml`
2. Scripts: `scripts/setup/`
3. Monitoring: `monitoring/`
4. Runbooks: `docs/operations/runbooks/`

---

## ✅ Clean Structure Benefits

1. **Easy Navigation**: Clear hierarchy and naming
2. **Separation of Concerns**: Each directory has a single purpose
3. **Scalability**: Easy to add new components
4. **Maintainability**: Clear where to find and update files
5. **Onboarding**: New developers can quickly understand structure
6. **Documentation**: Everything is well-documented and organized

---

**Need help finding something?** Check the `README.md` or run `make help`
