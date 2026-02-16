# Use slim variant for faster download
FROM apache/airflow:2.8.0-python3.11

USER root

# Install only essential dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

USER airflow

# Install Python packages (minimal set)
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
