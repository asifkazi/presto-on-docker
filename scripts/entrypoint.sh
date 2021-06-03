#!/usr/bin/env bash
set -e


#############################
# Default Values
#############################

# node
: "${PRESTO_NODE_ENVIRONMENT:=docker}"
: "${PRESTO_NODE_ID:=$(uuidgen)}"

# config
: "${PRESTO_CONF_COORDINATOR:=true}"
: "${PRESTO_CONF_INCLUDE_COORDINATOR:=true}"
: "${PRESTO_CONF_HTTP_PORT:=8080}"
: "${PRESTO_CONF_DISCOVERY_SERVER_ENABLED:=true}"
: "${PRESTO_CONF_DISCOVERY_URI:=http://localhost:8080}"
: "${PRESTO_CONF_QUERY_MAX_MEMORY:=5GB}"
: "${PRESTO_CONF_QUERY_MAX_MEMORY_PER_NODE:=1GB}"
: "${PRESTO_CONF_QUERY_MAX_TOTAL_MEMORY_PER_NODE:=2GB}"

# catalogs
# jmx
: "${PRESTO_CATALOG_JMX:=true}"
: "${PRESTO_CATALOG_JMX_NAME:=jmx}"

# hive
: "${PRESTO_CATALOG_HIVE:=false}"
: "${PRESTO_CATALOG_HIVE_NAME:=hive}"
: "${PRESTO_CATALOG_HIVE_METASTORE_URI:=file}"
: "${PRESTO_CATALOG_HIVE_RECURSIVE_DIRECTORIES:=true}"
: "${PRESTO_CATALOG_HIVE_ALLOW_DROP_TABLE:=true}"
: "${PRESTO_CATALOG_HIVE_USE_S3:=false}"
: "${PRESTO_CATALOG_HIVE_S3_AWS_ACCESS_KEY:=}"
: "${PRESTO_CATALOG_HIVE_S3_AWS_SECRET_KEY:=}"
: "${PRESTO_CATALOG_HIVE_S3_ENDPOINT:=}"
: "${PRESTO_CATALOG_HIVE_S3_USE_INSTANCE_CREDENTIALS:=false}"
: "${PRESTO_CATALOG_HIVE_S3_SELECT_PUSHDOWN_ENABLED:=true}"


#############################
# node.properties
#############################
{
    echo "node.environment=${PRESTO_NODE_ENVIRONMENT}"
    echo "node.id=${PRESTO_NODE_ID}"
    echo "catalog.config-dir=/etc/presto/catalog"
    echo "plugin.dir=/usr/lib/presto/lib/plugin"
} > /etc/presto/node.properties


#############################
# config.properties
#############################
{
    echo "coordinator=${PRESTO_CONF_COORDINATOR}"
    echo "http-server.http.port=${PRESTO_CONF_HTTP_PORT}"
    echo "discovery.uri=${PRESTO_CONF_DISCOVERY_URI}"
    echo "query.max-memory=${PRESTO_CONF_QUERY_MAX_MEMORY}"
    echo "query.max-memory-per-node=${PRESTO_CONF_QUERY_MAX_MEMORY_PER_NODE}"
    echo "query.max-total-memory-per-node=${PRESTO_CONF_QUERY_MAX_TOTAL_MEMORY_PER_NODE}"
    
    # Only write out coordinator specific configs if this is a coordinator
    if [ $PRESTO_CONF_COORDINATOR == "true" ]; then
        echo "discovery-server.enabled=${PRESTO_CONF_DISCOVERY_SERVER_ENABLED}"
        echo "node-scheduler.include-coordinator=${PRESTO_CONF_INCLUDE_COORDINATOR}"
    fi

} > /etc/presto/config.properties


#############################
# catalogs
#############################

# jmx
if [ $PRESTO_CATALOG_JMX == "true" ]; then
    {
        echo "connector.name=jmx"
    } > "/etc/presto/catalog/${PRESTO_CATALOG_JMX_NAME}.properties"
fi

# hive
if [ $PRESTO_CATALOG_HIVE == "true" ]; then
    {
        echo "connector.name=hive-hadoop2"
        echo "hive.recursive-directories=${PRESTO_CATALOG_HIVE_RECURSIVE_DIRECTORIES}"
        echo "hive.allow-drop-table=${PRESTO_CATALOG_HIVE_ALLOW_DROP_TABLE}"

        # use a real metastore, or a file-based metastore
        if [ $PRESTO_CATALOG_HIVE_METASTORE_URI == "file" ]; then
            echo "hive.metastore=file"
            echo "hive.metastore.catalog.dir=file:///tmp/hive_catalog"
            echo "hive.metastore.user=presto"
        else
            echo "hive.metastore.uri=${PRESTO_CATALOG_HIVE_METASTORE_URI}"
        fi

        # s3 on hive    
        if [ $PRESTO_CATALOG_HIVE_USE_S3 == "true" ]; then
            echo "hive.s3.aws-access-key=${PRESTO_CATALOG_HIVE_S3_AWS_ACCESS_KEY}"
            echo "hive.s3.aws-secret-key=${PRESTO_CATALOG_HIVE_S3_AWS_SECRET_KEY}"
            echo "hive.s3.endpoint=${PRESTO_CATALOG_HIVE_S3_ENDPOINT}"
            echo "hive.s3.use-instance-credentials=${PRESTO_CATALOG_HIVE_S3_USE_INSTANCE_CREDENTIALS}"
            echo "hive.s3select-pushdown.enabled=${PRESTO_CATALOG_HIVE_S3_SELECT_PUSHDOWN_ENABLED}"
        fi
    } > "/etc/presto/catalog/${PRESTO_CATALOG_HIVE_NAME}.properties"
fi


#############################
# execute
#############################
echo "Executing: $@"
exec "$@"
