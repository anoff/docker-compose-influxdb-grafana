#!/bin/sh
set -e

source .env

if [ -z "$INFLUX_TELEGRAF_PASSWORD" ]
then
  echo "\$INFLUX_TELEGRAF_PASSWORD is empty"
  exit 1
fi
if [ -z "$BASE_DIR" ]
then
  echo "\$BASE_DIR is empty"
  exit 1
fi
if [ -z "$INFLUXDB_USERNAME" ]
then
  echo "\$INFLUXDB_USERNAME is empty"
  exit 1
fi
if [ -z "$INFLUXDB_PASSWORD" ]
then
  echo "\$INFLUXDB_PASSWORD is empty"
  exit 1
fi

STORAGE_DIR=$BASE_DIR

echo "..creating mount points in $STORAGE_DIR"
mkdir -p $STORAGE_DIR/influxdb/data
mkdir -p $STORAGE_DIR/influxdb/init
mkdir -p $STORAGE_DIR/grafana/data
mkdir -p $STORAGE_DIR/grafana/provisioning
mkdir -p $STORAGE_DIR/compose-files/monitoring

echo "..copying docker-compose.yml and .env to $STORAGE_DIR/compose-files/monitoring"
cp docker-compose.yml $STORAGE_DIR/compose-files/monitoring/
cp .env $STORAGE_DIR/compose-files/monitoring/
echo "..copying influxdb init scripts to $STORAGE_DIR/influxdb/init"
cp assets/influxdb-init/* $STORAGE_DIR/influxdb/init

# get influxdb config and activate http auth
cd $STORAGE_DIR/influxdb
echo "..creating $STORAGE_DIR/influxdb/influxdb.conf"
docker run --rm influxdb:1.8 influxd config > influxdb.conf
echo "..modifying $STORAGE_DIR/influxdb/influxdb.conf"
sed -i .bak 's/^  auth-enabled = false$/  auth-enabled = true/g' influxdb.conf
# hotfix the influxdb init query to use the actual telegraf user password from .env
cd $STORAGE_DIR/influxdb/init
sed -i .bak 's/<telegrafUSERpassword>/'$INFLUX_TELEGRAF_PASSWORD'/g' create-telegraf.iql

### get telegraf config and set ports and credentials
cd $STORAGE_DIR/influxdb
echo "..creating $STORAGE_DIR/influxdb/telegraf.conf"
docker run --rm telegraf telegraf config > telegraf.conf
echo "..modifying $STORAGE_DIR/influxdb/telegraf.conf"
# now modify it to tell it how to authenticate against influxdb
sed -i .bak 's/^  # urls = \["http:\/\/127\.0\.0\.1:8086"\]$/  urls = \["http:\/\/influxdb:8086"\]/g' telegraf.conf
sed -i .bak 's/^  # database = "telegraf"$/  database = "telegraf"/' telegraf.conf
sed -i .bak 's/^  # username = "telegraf"$/  username = "telegraf"/' telegraf.conf
sed -i .bak 's/^  # password = "metricsmetricsmetricsmetrics"$/  password = "'$INFLUX_TELEGRAF_PASSWORD'"/' telegraf.conf
# as we run inside docker, the telegraf hostname is different from our Raspberry hostname, let's change it
sed -i .bak 's/^  hostname = ""$/  hostname = "'${HOSTNAME}'"/' telegraf.conf

### get grafana config
cd $STORAGE_DIR/grafana
echo "..creating $STORAGE_DIR/grafana/grafana.ini"
docker run --rm --entrypoint /bin/bash grafana/grafana:latest -c 'cat $GF_PATHS_CONFIG' > grafana.ini
echo "..changing permissions for $STORAGE_DIR/grafana/data to 472:472"
echo '>> Please enter sudo password for chown operation <<'
sudo chown 472:472 $STORAGE_DIR/grafana/data

echo "..setting mount paths in $STORAGE_DIR/compose-files/monitoring/docker-compose.yml to $STORAGE_DIR"
ESCAPED_PATH=$(printf '%s\n' "$STORAGE_DIR" | sed -e 's/[\/&]/\\&/g')
sed -i .bak 's/$HOME\/docker/'"$ESCAPED_PATH"'/' $STORAGE_DIR/compose-files/monitoring/docker-compose.yml