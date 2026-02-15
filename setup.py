from setuptools import setup, find_packages

setup(
    name="snapptrip-data-platform",
    version="1.0.0",
    description="Enterprise Lakehouse Data Platform for SnappTrip",
    author="SnappTrip Data Engineering Team",
    author_email="data-engineering@snapptrip.com",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.9",
    install_requires=[
        "pyspark>=3.5.0",
        "kafka-python>=2.0.2",
        "great-expectations>=0.18.0",
        "pyiceberg>=0.5.0",
        "psycopg2-binary>=2.9.0",
        "prometheus-client>=0.19.0",
        "python-dotenv>=1.0.0",
        "pyyaml>=6.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
            "chispa>=0.9.0",
            "black>=23.0.0",
            "flake8>=7.0.0",
            "mypy>=1.8.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "snapptrip-ingest=ingestion.kafka_producer:main",
            "snapptrip-bronze=bronze.kafka_to_iceberg:main",
            "snapptrip-silver=silver.booking_state_reconciliation:main",
            "snapptrip-gold=gold.daily_kpi_aggregator:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
