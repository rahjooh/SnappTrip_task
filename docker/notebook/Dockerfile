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

# So notebook code can use namenode:9000 when running in Docker
ENV LAKEHOUSE_WAREHOUSE=hdfs://namenode:9000/lakehouse

EXPOSE 8888
WORKDIR /workspace
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
