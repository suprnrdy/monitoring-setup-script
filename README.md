# Script for Setting up Promethus and Loki
This is a shell script which automates the installation and configuration for Prometheus (with cAdvisor and NodeExporter) and Loki. This script performs following tasks:

* Installs Pre-requisites, `cURL` and `docker-compose`, if required
* Configures `prometheus.yml`, `docker-compose.yml` for Prometheus. **Including Prometheus task for Metrics scraping from Keep Random Beacon or ECDSA Nodes**
* Permission setup on Prometheus folder for the prom container to start correctly
* Loki Docker driver installation and configuration
* Loki `docker-compose.yml` and `local-config.yaml`

## Before you run the script
* This script does not setup random beacon or ECDSA nodes. It assumes you are already running one of these nodes and want to setup monitoring using Prometheus, Loki and Grafana.
* Allow access to Ports 9090, 8081 and 3100 from the IP where you run Random Beacon or ECDSA nodes. For example, if you are running ECDSA node on 50.234.1.88 then whitelist `50.234.1.88` to access ports 9090, 8081 and 3100 in network settings of the server.
* Whitelist Grafana hosted environment IPs available at https://grafana.com/api/hosted-grafana/source-ips.txt (if you are using Grafana cloud) in network settings of your random beacon or ECDSA node. 
* Add the following to `config.toml` of your Random Beacon or ECDSA node

```
[Metrics]
    Port = 8080
    NetworkMetricsTick = 60
    EthereumMetricsTick = 600
```

## Steps to Run the Script
* Download the script to the server where you are running Random Beacon or ECDSA node
* Run the script using `./configure-monitoring.sh`
