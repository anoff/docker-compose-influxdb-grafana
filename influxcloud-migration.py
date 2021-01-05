#!python3
# This script migrates data from InfluxCloud to a InfluxDB v1 instance

# https://github.com/influxdata/influxdb-client-python
from influxdb_client import InfluxDBClient as InfluxDBClientV2

# https://github.com/influxdata/influxdb-python
from influxdb import InfluxDBClient as InfluxDBClientV1

import json
import pandas as pd
client = InfluxDBClientV2(
  url="https://us-west-2-1.aws.cloud2.influxdata.com",
  token="",
  org=""
)

client_local = InfluxDBClientV1(username="", password="", database="")


query_api = client.query_api()
records = query_api.query_stream('from(bucket:"savr") |> range(start: -7d, stop: now())')

i = 0
for record in records:
  i += 1
  json_body = [{
    "measurement": record["_measurement"],
    "tags": {
    },
    "time": record.get_time().isoformat(),
    "fields": {
      record["_field"]: record["_value"]
    }
  }]
  # popuplate tags
  for k in [k for k in list(record.values.keys()) if (k[0] != "_" and k not in ["result", "table"])]:
    json_body[0]["tags"][k] = record[k]

  client_local.write_points(json_body)
  if i % 100 == 0:
    print(f'..synced {i} records')

print(f'Total records: {i}')