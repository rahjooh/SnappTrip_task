# Use Eclipse Temurin 11 JRE (Ubuntu-based, better compatibility)
FROM eclipse-temurin:11-jre-jammy

ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Install dependencies (Debian uses apt-get)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    bash \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Download and install Hadoop (use closer mirror)
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Create directories
RUN mkdir -p /hadoop/dfs/name /hadoop/dfs/data

# Copy configuration files
COPY core-site.xml ${HADOOP_CONF_DIR}/core-site.xml
COPY hdfs-site.xml ${HADOOP_CONF_DIR}/hdfs-site.xml
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
