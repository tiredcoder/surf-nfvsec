#!/usr/bin/env bash
#
# init.sh - VNF init script: Send VNF class and data plane IP address to NFV controller.
# Author: Rik Janssen <Rik.Janssen@os3.nl>
# Project: UvA, SNE/OS3, RP2
#
# Requires that the following env variables have been set via Docker/K8S: 
#  - DATA_NET, used to get the IP address of the NF (e.g., DATA_NET=10.200)
#  - NFV_CTRL, DNS name or IP address of the NFV Controller (e.g., 'nfv-controller')
#  - FILTER, defines the tcpdump filter
#

# Remove NF from controller when stopping container
_term() {
  curl --request DELETE http://$NFV_CTRL:80/api/vnf/$VNF_ID
  kill -TERM "$child" 2>/dev/null
}
trap _term SIGTERM

# Default CMD
if [ "$1" = 'default' ]; then
  DATA_NET_IP_ADDR=$(hostname --all-ip-addresses | grep -o "\b$DATA_NET.*" | cut -d' ' -f 1)
  DATA="{\"class\":\"$VNF_CLASS\",\"ip\":\"$DATA_NET_IP_ADDR\"}"
  export VNF_ID=$(curl --header "Content-Type: application/json" --request PUT --data "$DATA" http://$NFV_CTRL:80/api/vnf)

  # CMD
  gosu root tcpdump -Uw /surf/vnf-tcpdump-log.pcap ${FILTER[@]} &

  child=$!
  wait "$child"
else
  # CMD override (used for debug)
  exec "$@"
fi

