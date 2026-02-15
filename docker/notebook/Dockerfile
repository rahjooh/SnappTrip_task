# Jupyter + PySpark on same Docker network as HDFS (avoids "RPC response has invalid length" when using HDFS from host)
FROM eclipse-temurin:17-jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# PySpark 3.5 + Jupyter; Hadoop 3.3.6 is pulled via spark.jars.packages in notebook to match Docker HDFS
RUN pip3 install --no-cache-dir \
    "pyspark==3.5.0" \
    "jupyterlab>=4.0" \
    "notebook>=7.0"
# Project deps for notebooks (confluent_kafka, pandas, postgres, etc.)
COPY requirements-notebook.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements-notebook.txt

# DBT CLI so notebooks can run "dbt run" when not using docker compose (e.g. inside notebook container)
# Pin protobuf<5 to avoid MessageToJson(including_default_value_fields) TypeError with dbt-core 1.7.x
RUN pip3 install --no-cache-dir "protobuf>=3.20,<5" "dbt-core==1.7.4" "dbt-spark==1.7.1"

# So notebook code can use namenode:9000 when running in Docker
ENV LAKEHOUSE_WAREHOUSE=hdfs://namenode:9000/lakehouse

# So "import src" works in notebooks (src is mounted at /workspace/src)
RUN python3 -c "import site; p=site.getsitepackages()[0]; open(p+'/workspace.pth','w').write('/workspace\n')"

EXPOSE 8888
WORKDIR /workspace
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--ServerApp.token=", "--ServerApp.password="]
