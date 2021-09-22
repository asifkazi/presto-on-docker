#!/usr/bin/env bash
set -e


#############################
# Default Values
#############################
: "${PRESTO_JVM_MEMORY_MS_MX:=8G}"
: "${PRESTO_JVM_SETTINGS:=-server \
-Xmx${PRESTO_JVM_MEMORY_MS_MX} \
-XX:-UseBiasedLocking \
-XX:+UseG1GC \
-XX:+ExplicitGCInvokesConcurrent \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:+UseGCOverheadLimit \
-XX:+ExitOnOutOfMemoryError \
-XX:ReservedCodeCacheSize=512M}"

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
: "${PRESTO_CATALOG_TPCDS:=true}"
: "${PRESTO_CATALOG_TPCH:=true}"
: "${PRESTO_CATALOG_BLACKHOLE:=true}"


# hive
: "${PRESTO_CATALOG_HIVE:=true}"
: "${PRESTO_CATALOG_HIVE_NAME:=hive}"


# hive-s3
: "${PRESTO_CATALOG_HIVE_USE_S3:=true}"
: "${PRESTO_CATALOG_HIVE_S3_AWS_ACCESS_KEY:=}"
: "${PRESTO_CATALOG_HIVE_S3_AWS_SECRET_KEY:=}"
: "${PRESTO_CATALOG_HIVE_S3_ENDPOINT:=}"
: "${PRESTO_CATALOG_HIVE_S3_IAM_ROLE:=}"
: "${PRESTO_CATALOG_HIVE_S3_USE_INSTANCE_CREDENTIALS:=false}"
: "${PRESTO_CATALOG_HIVE_S3_SELECT_PUSHDOWN_ENABLED:=true}"


# hive glue
: "${PRESTO_CATALOG_HIVE_METASTORE_URI:=glue}" #Options are file,glue or a specific thrift endpoint
: "${PRESTO_CATALOG_HIVE_METASTORE_GLUE_REGION:=us-east-1}" 
: "${PRESTO_CATALOG_HIVE_METASTORE_GLUE_IAM_ROLE:=}"  
: "${PRESTO_CATALOG_HIVE_GLUE_AWS_ACCESS_KEY:=}"
: "${PRESTO_CATALOG_HIVE_GLUE_AWS_SECRET_KEY:=}"


# mysql
: "${PRESTO_CATALOG_MYSQL:=true}"
: "${PRESTO_CATALOG_MYSQL_NAME:=mysql}"
: "${PRESTO_CATALOG_MYSQL_HOST:=mysql}"
: "${PRESTO_CATALOG_MYSQL_PORT:=3306}"
: "${PRESTO_CATALOG_MYSQL_USER:=dbuser}"
: "${PRESTO_CATALOG_MYSQL_PASSWORD:=dbuser}"

#############################
# jvm.config
#############################
presto_jvm_config() {
    for i in ${PRESTO_JVM_SETTINGS}
        do
            prnt="$prnt\n$i"       # New line directly 
        done
    echo -e "${prnt:2}"  # Trim the leading newline
            
} > /etc/presto/jvm.config

#############################
# log.properties
#############################
presto_log_config() {
    echo "com.facebook.presto=INFO"  
    echo "com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory=WARN"
    echo "com.ning.http.client=WARN"
    echo "com.facebook.presto.server.PluginManager=DEBUG"            
} > /etc/presto/log.properties


#############################
# node.properties
#############################
presto_node_config()
{
    echo "node.environment=${PRESTO_NODE_ENVIRONMENT}"
    echo "node.id=${PRESTO_NODE_ID}"
    echo "catalog.config-dir=/etc/presto/catalog"
    echo "plugin.dir=/usr/lib/presto/lib/plugin"
} > /etc/presto/node.properties


#############################
# config.properties
#############################
presto_settings_config()
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
# catalog jmx
#############################
catalog_jmx_config()
{
    echo "connector.name=jmx"
} > "/etc/presto/catalog/jmx.properties"


#############################
# catalog tpcds
#############################
catalog_tpcds_config()
{
    echo "connector.name=tpcds"
} > "/etc/presto/catalog/tpcds.properties"

#############################
# catalog tpch
#############################
catalog_tpch_config()
{
    echo "connector.name=tpch"
} > "/etc/presto/catalog/tpch.properties"

#############################
# catalog blackhole
#############################
catalog_blackhole_config()
{
    echo "connector.name=blackhole"
} > "/etc/presto/catalog/blackhole.properties"


#############################
# catalog hive
#############################
catalog_hive_config()
{
    #Defaults
    echo "connector.name=hive-hadoop2"
    echo "hive.collect-column-statistics-on-write=true"
    echo "hive.recursive-directories=true"
    echo "hive.orc.use-column-names=true"
    echo "hive.parquet.use-column-names=true"
    echo "hive.allow-drop-table=true"
    echo "hive.allow-rename-table=true"
    echo "hive.allow-add-column=true"
    echo "hive.allow-drop-column=true"
    echo "hive.allow-rename-column=true"
    echo "hive.non-managed-table-writes-enabled=true"
    echo "hive.non-managed-table-creates-enabled=true"
    
    # use a real metastore, or a file-based metastore
    if [ $PRESTO_CATALOG_HIVE_METASTORE_URI == "file" ]; then
        echo "hive.metastore=file"
        echo "hive.metastore.catalog.dir=file:///tmp/hive_catalog"
        echo "hive.metastore.user=presto"
    elif [ $PRESTO_CATALOG_HIVE_METASTORE_URI == "glue" ]; then
        echo "hive.metastore=glue"
        echo "hive.metastore.glue.aws-access-key=${PRESTO_CATALOG_HIVE_GLUE_AWS_ACCESS_KEY}"
        echo "hive.metastore.glue.aws-secret-key=${PRESTO_CATALOG_HIVE_GLUE_AWS_SECRET_KEY}"
        echo "hive.metastore.glue.region=${PRESTO_CATALOG_HIVE_METASTORE_GLUE_REGION}"
        echo "hive.metastore.glue.iam-role=${PRESTO_CATALOG_HIVE_METASTORE_GLUE_IAM_ROLE}"
  
    else
        echo "hive.metastore.uri=${PRESTO_CATALOG_HIVE_METASTORE_URI}"
    fi

    # s3 on hive    
    if [ $PRESTO_CATALOG_HIVE_USE_S3 == "true" ]; then
        echo "hive.s3.aws-access-key=${PRESTO_CATALOG_HIVE_S3_AWS_ACCESS_KEY}"
        echo "hive.s3.aws-secret-key=${PRESTO_CATALOG_HIVE_S3_AWS_SECRET_KEY}"
        echo "hive.s3.iam-role=${PRESTO_CATALOG_HIVE_S3_IAM_ROLE}"
        #Enable for custom endpoint only like minio
        #echo "hive.s3.endpoint=${PRESTO_CATALOG_HIVE_S3_ENDPOINT}"
        echo "hive.s3.use-instance-credentials=${PRESTO_CATALOG_HIVE_S3_USE_INSTANCE_CREDENTIALS}"
        echo "hive.s3select-pushdown.enabled=${PRESTO_CATALOG_HIVE_S3_SELECT_PUSHDOWN_ENABLED}"
    fi
} > "/etc/presto/catalog/${PRESTO_CATALOG_HIVE_NAME}.properties"

#############################
# catalog mysql
#############################
catalog_mysql_config() 
{
    echo "connector.name=mysql"
    echo "connection-url=jdbc:mysql://${PRESTO_CATALOG_MYSQL_HOST}:${PRESTO_CATALOG_MYSQL_PORT}?useSSL=false"
    echo "connection-user=${PRESTO_CATALOG_MYSQL_USER}"
    echo "connection-password=${PRESTO_CATALOG_MYSQL_PASSWORD}"
} >/etc/presto/catalog/${PRESTO_CATALOG_MYSQL_NAME}.properties

#############################
# Let er rip
#############################
presto_log_config
presto_jvm_config
presto_settings_config
presto_node_config


# jmx
if [ $PRESTO_CATALOG_JMX == "true" ]; then
    catalog_jmx_config
fi

# tpcds
if [ $PRESTO_CATALOG_TPCDS == "true" ]; then
    catalog_tpcds_config
fi

# tpch
if [ $PRESTO_CATALOG_TPCH == "true" ]; then
    catalog_tpch_config
fi

# blackhole
if [ $PRESTO_CATALOG_BLACKHOLE == "true" ]; then
    catalog_blackhole_config
fi

# hive
if [ $PRESTO_CATALOG_HIVE == "true" ]; then
    catalog_hive_config
fi

# hive
if [ $PRESTO_CATALOG_MYSQL == "true" ]; then
    catalog_mysql_config
fi

#############################
# execute
#############################
echo "Executing: $@"
exec "$@"
