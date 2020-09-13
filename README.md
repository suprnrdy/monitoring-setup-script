# Script for Setting up Promethus and Loki
This is a shell script which automates the installation and configuration for Prometheus (with cAdvisor and NodeExporter) and Loki. This script performs following tasks:

* Installs Pre-requisites, `cURL` and `docker-compose`, if required
* Configures `prometheus.yml`, `docker-compose.yml` for Prometheus. **Including Prometheus task for Metrics scraping from Keep Random Beacon or ECDSA Nodes**
* Permission setup on Prometheus folder for the prom container to start correctly
* Loki Docker driver installation and configuration
* Loki `docker-compose.yml` and `local-config.yaml`

This script automates the setup steps described on https://medium.com/@hr12rtk/keep-random-beacon-node-monitoring-grafana-prometheus-and-loki-4a4b669b31ea. You could still use the Medium article to get a idea of the setup and create free Grafana Cloud Account (under *Create Grafana Cloud Starter Account* section). Grafana will be used to create the dashboards for data collected using Prometheus and Loki setup done by `configure-monitoring.sh`.

## Before you run the script
* This script does not setup random beacon or ECDSA nodes. It assumes you are already running one of these nodes and want to setup monitoring using Prometheus, Loki and Grafana.
* Allow access to Ports 9090, 8081 and 3100 from the IP where you run Random Beacon or ECDSA nodes. For example, if you are running ECDSA node on 50.234.1.88 then whitelist `50.234.1.88` to access ports 9090, 8081 and 3100 in network settings of the server.
* Whitelist Grafana hosted environment IPs available at https://grafana.com/api/hosted-grafana/source-ips.txt (if you are using Grafana cloud) in network settings of your random beacon or ECDSA node. Please refer to *IP Whitelisting for Hosted Grafana Instances* section at https://medium.com/@hr12rtk/keep-random-beacon-node-monitoring-part-2-5cd037464a6e for more details.

 
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
* Respond to the prompts on screen. The first prompt is for if you want to install cURL. It is used for installing docker-compose. if you enter 1, it installs cURL, else moves to next step.

```console
install CURL? (1 - yes, default - no) >
```


* In next step it asks if you want to install `docker-compose`. If you already have `docker-compose` then you can simply press enter and move to next step, else you can enter 1 on the promt and it will install `docker-compose`

```console
install docker-compose? (1 - yes, default - no) >
```

* This step asks if you want to install and configure Prometheus, cAdvisor and NodeExporter. Enter `1` on the command prompt to start the configuration. This step would configure and start Prometheus, cAdvisor and NodeExporter docker containers.

```console
Configure Prometheus, cAdvisor and NodeExporter? (1 - yes, default - no) >
```

* In the last step Configure Loki by entering `1` on command prompt in this step. It would install Loki Docker driver, do driver the configuration in /etc/docker/daemon.json and start Loki docker container

```console
Configure Loki? (1 - yes, default - no) >
```

This completes the setup. To validate if all the containers have started successfully use `sudo docker ps -a` and you should see an output similar to following.

````
CONTAINER ID        IMAGE                                       COMMAND                  CREATED             STATUS              PORTS                                            NAMES
836097d168de        grafana/loki:latest                         "/usr/bin/loki -conf…"   10 seconds ago      Up 7 seconds        0.0.0.0:3100->3100/tcp                           loki
11c0ee355f4f        prom/prometheus:latest                      "/bin/prometheus --c…"   31 seconds ago      Up 30 seconds       0.0.0.0:9090->9090/tcp                           monitoring_prometheus
6221c253b8b4        google/cadvisor:latest                      "/usr/bin/cadvisor -…"   35 seconds ago      Up 31 seconds       8080/tcp                                         monitoring_cadvisor
84a02881907d        prom/node-exporter:latest                   "/bin/node_exporter"     35 seconds ago      Up 31 seconds       9100/tcp                                         monitoring_node_exporter
````

## Restart Keep Node (Random Beacon or ECDSA)
In order for the Keep nodes to start sending logs to Loki and expose the Metrics to Prometheus scraping job you need to restart the Keep node. The Docker command should be updated to include parameters for loki log driver location and port for exposing the Metrics. Following is a sample command for ECDSA.

```console
export KEEP_ECDSA_PERSISTENCE_DIR=PERSISTENCE-DIR-PATH
export KEEP_ECDSA_KEYSTORE_DIR=KEYSTORE-DIR-PATH
export KEEP_ECDSA_CONFIG_DIR=CONFIG-DIR-PATH
export KEEP_ECDSA_ETHEREUM_PASSWORD=ETHEREUM-WALLET-PASSWORD

sudo docker run -dit \
--restart unless-stopped \
--log-driver loki \
--log-opt loki-url="http://SERVER_IP:3100/loki/api/v1/push" \
--volume $KEEP_ECDSA_PERSISTENCE_DIR:/mnt/keep-ecdsa/persistence \
--volume $KEEP_ECDSA_KEYSTORE_DIR:/mnt/keep-ecdsa/keystore \
--volume $KEEP_ECDSA_CONFIG_DIR:/mnt/keep-ecdsa/config \
--env KEEP_ETHEREUM_PASSWORD=$KEEP_ECDSA_ETHEREUM_PASSWORD \
--env LOG_LEVEL=debug \
--name ecdsa \
-p 3919:3919 \
-p 8081:8080 \
keepnetwork/keep-ecdsa-client:v1.2.0-rc.5 --config /mnt/keep-ecdsa/config/config.toml start
```
Check if the node has started by using `sudo docker ps -a`. This command should show an output similar to following.

```
CONTAINER ID        IMAGE                                       COMMAND                  CREATED             STATUS              PORTS                                            NAMES
836097d168de        grafana/loki:latest                         "/usr/bin/loki -conf…"   10 seconds ago      Up 7 seconds        0.0.0.0:3100->3100/tcp                           loki
11c0ee355f4f        prom/prometheus:latest                      "/bin/prometheus --c…"   31 seconds ago      Up 30 seconds       0.0.0.0:9090->9090/tcp                           monitoring_prometheus
6221c253b8b4        google/cadvisor:latest                      "/usr/bin/cadvisor -…"   35 seconds ago      Up 31 seconds       8080/tcp                                         monitoring_cadvisor
84a02881907d        prom/node-exporter:latest                   "/bin/node_exporter"     35 seconds ago      Up 31 seconds       9100/tcp                                         monitoring_node_exporter
3dc810fedf94        keepnetwork/keep-ecdsa-client:v1.2.0-rc.5   "/usr/local/bin/keep…"   2 hours ago         Up 2 hours          0.0.0.0:3919->3919/tcp, 0.0.0.0:8081->8080/tcp   ecdsa
```

## Create Grafana Dashboards
Please follow the instructions on https://medium.com/@hr12rtk/keep-random-beacon-node-monitoring-part-2-5cd037464a6e to create Grafana dashboards using Prometheus and Loki data sources.



