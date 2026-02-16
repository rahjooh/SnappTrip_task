#!/bin/bash

# Format namenode if needed
if [ "$1" = "hdfs" ] && [ "$2" = "namenode" ]; then
    if [ ! -d "/hadoop/dfs/name/current" ]; then
        echo "Formatting namenode..."
        hdfs namenode -format -force
    fi
fi

# Execute command
exec "$@"
