#!/bin/bash

#install pre-requs
echo -n "install CURL? (1 - yes, default - no) > "
read installcurl
echo
if test "$installcurl" == "1"
then
    sudo apt-get update && sudo apt-get install curl
fi
echo -n "install docker-compose? (1 - yes, default - no) > "
read installdockercompose
echo
if test "$installdockercompose" == "1"
then
    sudo rm -rf /usr/local/bin/docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

#Setup Prometheus, cAdvisor and NodeExporter
echo -n "Install Prometheus, cAdvisor and NodeExporter? (1 - yes, default - no) > "
read installpcn

if test "$installpcn" == "1"
then
    echo "Starting Prometheus, cAdvisor and NodeExporter configuration"
    echo
    mkdir ~/prometheus 
    mkdir ~/prometheus/prometheus-data
    git clone https://github.com/mutedtommy/prom-loki-configs.git ~/prom-loki-configs
    cp ~/prom-loki-configs/prometheus/prometheus.yml ~/prometheus/prometheus.yml
    cd ~/prometheus
    SERVER_IP=$(curl ifconfig.me)
    echo $SERVER_IP
    sudo sed -i "s/REPLACE-WITH-SERVER-IP/$SERVER_IP/" prometheus.yml
    cp ~/prom-loki-configs/prometheus/docker-compose.yml ~/prometheus/docker-compose.yml
    cd ..
    chmod -R 777 prometheus
    cd prometheus
    sudo docker-compose up -d

    echo "Configured Prometheus, cAdvisor and NodeExporter"
    echo
fi
echo
echo -n "Install Loki? (1 - yes, default - no) > "
read installloki

if test "$installloki" == "1"
then
    #setup & run Loki
    echo "Starting Loki configuration"
    echo
    cd ~
    mkdir loki
    cd loki
    cp ~/prom-loki-configs/loki/docker-compose.yml ~/loki/docker-compose.yml
    cp ~/prom-loki-configs/loki/local-config.yaml ~/loki/local-config.yaml

    #install Loki Docker Driver
    sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

    cd /etc/docker
    sudo cp ~/prom-loki-configs/loki/daemon.json daemon.json
    sudo sed -i "s/REPLACE-WITH-SERVER-IP/$SERVER_IP/" daemon.json

    cd ~/loki
    sudo docker-compose up -d

    echo "Configured Loki"
    echo
fi


echo
echo
echo "Restart Keep Docker Containers with Loki Node Exporter and Metrics Port (8081:8080)"
echo "------------------------------------------------------------------------------------"
echo "sample command"
echo "------------------------------------------------------------------------------------"
echo
echo "sudo docker run -dit \
--restart unless-stopped \
--log-driver loki \
--log-opt loki-url="http://LOKI-HOST-IP:3100/loki/api/v1/push" \
--entrypoint /usr/local/bin/keep-ecdsa \
--volume \$KEEP_ECDSA_PERSISTENCE_DIR:/mnt/keep-ecdsa/persistence \
--volume \$KEEP_ECDSA_KEYSTORE_DIR:/mnt/keep-ecdsa/keystore \
--volume \$KEEP_ECDSA_CONFIG_DIR:/mnt/keep-ecdsa/config \
--env KEEP_ETHEREUM_PASSWORD=\$KEEP_ECDSA_ETHEREUM_PASSWORD \
--env LOG_LEVEL=debug \
--name ecdsa \
-p 3919:3919 \
-p 8081:8080 \
keepnetwork/keep-ecdsa-client:v1.2.0-rc.5 --config /mnt/keep-ecdsa/config/config.toml start"
echo
echo "------------------------------------------------------------------------------------"
