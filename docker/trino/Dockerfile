# Use latest stable Trino (smaller, faster)
FROM trinodb/trino:438

USER root

# Copy configuration files
COPY config.properties /etc/trino/config.properties
COPY jvm.config /etc/trino/jvm.config
COPY catalog/*.properties /etc/trino/catalog/

USER trino
