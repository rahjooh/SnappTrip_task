.PHONY: help install test lint format clean docker-up docker-down init-data jupyter up down restart urls wait-kafka init-kafka-topics

help:
	@echo "SnappTrip Data Platform - Available Commands:"
	@echo ""
	@echo "Setup:"
	@echo "  make setup         - Create conda environment and install all dependencies"
	@echo "  make verify        - Verify environment setup"
	@echo ""
	@echo "Notebooks:"
	@echo "  make jupyter       - Start Jupyter Lab (no token/password, open http://localhost:8888)"
	@echo ""
	@echo "Development:"
	@echo "  make test          - Run all tests"
	@echo "  make test-unit     - Run unit tests only"
	@echo "  make test-integration - Run integration tests"
	@echo "  make lint          - Run linters (flake8, mypy)"
	@echo "  make format        - Format code with black and isort"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "Docker:"
	@echo "  make up            - Start services, create Kafka topics, print UI URLs"
	@echo "  make down          - Stop all services (containers kept, no removal)"
	@echo "  make restart       - Restart all services and ensure Kafka topics exist"
	@echo "  make docker-up     - Start all Docker services"
	@echo "  make docker-down   - Stop and remove containers (full teardown)"
	@echo "  make docker-logs   - View Docker logs"
	@echo "  make docker-clean  - Clean Docker volumes and images"
	@echo "  make urls          - Print all service UI URLs"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make init-infra    - Initialize infrastructure (HDFS, Kafka topics, etc.)"
	@echo "  make init-data     - Initialize sample data"
	@echo ""
	@echo "dbt:"
	@echo "  make dbt-run       - Run dbt models"
	@echo "  make dbt-test      - Run dbt tests"
	@echo "  make dbt-docs      - Generate and serve dbt docs"

setup:
	@echo "Setting up development environment..."
	bash scripts/dev/setup_environment.sh

verify:
	@echo "Verifying environment setup..."
	python verify_setup.py

test:
	pytest tests/ -v

test-unit:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v

lint:
	flake8 src/ tests/
	mypy src/

format:
	black src/ tests/
	isort src/ tests/

jupyter:
	jupyter lab notebooks/ --ServerApp.token='' --ServerApp.password='' --no-browser
	@echo "Open http://localhost:8888 (no login required)"

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf build/ dist/ .coverage htmlcov/ .pytest_cache/

up: docker-up wait-kafka init-kafka-topics urls

down:
	docker-compose -f docker/docker-compose.yml stop

restart: down docker-up wait-kafka init-kafka-topics urls

wait-kafka:
	@echo "Waiting for Kafka to be ready..."
	@sleep 20

init-kafka-topics:
	@bash scripts/setup/init_kafka_topics.sh

urls:
	@echo ""
	@echo "=============================================="
	@echo "  SnappTrip Data Platform - Service UIs"
	@echo "=============================================="
	@echo ""
	@echo "  Jupyter Lab:       http://localhost:8888"
	@echo "  HDFS NameNode:     http://localhost:9870"
	@echo "  Schema Registry:   http://localhost:8081"
	@echo "  Spark Master:      http://localhost:8082"
	@echo "  Airflow:           http://localhost:8090   (admin / admin)"
	@echo "  Trino:             http://localhost:8083"
	@echo "  Prometheus:        http://localhost:9090"
	@echo "  Grafana:           http://localhost:3000   (admin / admin)"
	@echo "  Alertmanager:      http://localhost:9093"
	@echo ""
	@echo "  PostgreSQL:        localhost:5432"
	@echo "  Kafka (broker 1):  localhost:19092"
	@echo ""
	@echo "=============================================="

docker-up:
	docker-compose -f docker/docker-compose.yml up -d

docker-down:
	docker-compose -f docker/docker-compose.yml down

docker-logs:
	docker-compose -f docker/docker-compose.yml logs -f

docker-clean:
	docker-compose -f docker/docker-compose.yml down -v
	docker system prune -f

init-infra:
	bash scripts/setup/init_hdfs.sh
	bash scripts/setup/init_kafka_topics.sh
	bash scripts/setup/init_postgres.sh
	bash scripts/setup/init_schema_registry.sh

init-data:
	python src/ingestion/data_generator.py

dbt-run:
	cd dbt && dbt run

dbt-test:
	cd dbt && dbt test

dbt-docs:
	cd dbt && dbt docs generate && dbt docs serve
