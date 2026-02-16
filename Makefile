.PHONY: help install test lint format clean docker-up docker-down init-data

help:
	@echo "SnappTrip Data Platform - Available Commands:"
	@echo ""
	@echo "Setup:"
	@echo "  make setup         - Create conda environment and install all dependencies"
	@echo "  make verify        - Verify environment setup"
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
	@echo "  make docker-up     - Start all Docker services"
	@echo "  make docker-down   - Stop all Docker services"
	@echo "  make docker-logs   - View Docker logs"
	@echo "  make docker-clean  - Clean Docker volumes and images"
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

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf build/ dist/ .coverage htmlcov/ .pytest_cache/

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
