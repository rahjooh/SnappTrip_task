# Run DBT Spark (session) on same Docker network as HDFS to avoid RPC version mismatch
FROM eclipse-temurin:17-jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN pip3 install --no-cache-dir "dbt-core>=1.8" "dbt-spark[session]"

# Use base image's Java (eclipse-temurin sets JAVA_HOME=/opt/java/openjdk); do not override
WORKDIR /dbt
ENTRYPOINT ["dbt"]
