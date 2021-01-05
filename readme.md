# InfluxDB, Grafana, Traefik, Cloudflare DynDNS

> The ultimate stack for your self-hosted, internet accessible monitoring suite

This repository provides a `docker-compose` based solution to host the following services fully connected and ready-to-use.
All tools and services used in this setup have a free-to-use policy but please check if your specific use-case is covered by this.

## The stack

With all components in the compose file you will have Grafana and InfluxDB exposed to the internet.
Grafana will be routed through SSL encrypted **HTTPS** port with auto-redirect for any incoming HTTP traffic.
The InfluxDB endpoint will be plain **HTTP** (HTTPS did not work in all cases for me.)

![uncached image](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.github.com/anoff/docker-compose-influxdb-grafana/master/assets/stack.puml)

The compose file will start the following services:

* [InfluxDB](https://www.influxdata.com/products/influxdb/): as timeseries database for whatever you want to monitor
* [Chronograf](https://www.influxdata.com/time-series-platform/chronograf/): InfluxDB admin UI, only accessible from localhost because it lacks Authorization
* [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/): Powerful Ingest engine for InfluxDB to crawl/accept lots of data sources
* [Grafana](https://grafana.com/): Dashboard for visualizing data
* [traefik](https://traefik.io/): Get SSL certificates for grafana domain and route traffic for individual subdomains to correct docker services
* [cloudflare-ddns](https://github.com/oznu/docker-cloudflare-ddns): A lightweight container that will update cloudflare DNS records to your local IP address and give you a _dynamic DNS_ behavior but with a proper domain.

## Installation guide

Prerequisites:
- your own domain with DNS managed by [Cloudflare](https://www.cloudflare.com/dns/), this does not mean you need to buy the domain through cloudflare

If you want to run this yourself, you need to prepare the necessary folder structure which looks something like this:

```text
$BASE_DIR/
├── influxdb/
│   ├── data/ # influxdb working directory (where your actual data is stored)
│   ├── init/ # some init scripts to bootstrap the instance
│   ├── influxdb.conf # config for influxdb instance
│   └── telegraf.conf # config for telegraf instance
├── grafana/
│   ├── data/ # grafana working directory
│   ├── provisioning/ # placeholder for provisioning scripts that grafana will load on boot
│   └── grafana.ini # config for grafana instance
└── compose-files/
    └── monitoring
        ├── .env # file containing user secrets
        └── docker-compose.yml # specification of docker containers to run
```

This repo provides a little helper script to set up everything and provide the correct secrets where necessary.
All you need to do is

```sh
git clone git@github.com:anoff/docker-compose-influxdb-grafana.git
cd docker-compose-influxdb-grafana
cp .env.template .env
```

Now you need to modify the `.env` file to give it all credentials needed for the setup.

* INFLUX_TELEGRAF_PASSWORD: password for the 'telegraf' user that will be automatically created for the connection from telegraf to influxdb
* INFLUXDB_USERNAME: admin username 
* INFLUXDB_PASSWORD: admin password
* BASE_DIR: base directory for all docker mount points and the compose file (defaults to $HOME/docker)
* GF_SECURITY_ADMIN_USER: grafana admin username
* GF_SECURITY_ADMIN_PASSWORD: grafana admin password
* CLOUDFLARE_API_TOKEN: API token for your root domain on Cloudflare

By running `sh prepare-folders.sh` the folder structure will be created at `BASE_DIR` and the `docker-compose.yml` will be modified to point all mount paths to `BASE_DIR` as well.
You can find the modified compose file at `BASE_DIR/compose-files/monitoring/` from there you can star the stack using

```sh
# running it in the directory where you have your modified .env
source .env
cd $BASE_DIR/compose-files/monitoring
docker-compose up -d
```
