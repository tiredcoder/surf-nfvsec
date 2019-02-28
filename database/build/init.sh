#!/usr/bin/env bash
#
# init.sh - Container init script: create rqlite database cluster.
# Author: Rik Janssen <Rik.Janssen@os3.nl>
# Project: UvA, SNE/OS3, RP2
#
# Requires that the following env variables have been set via Docker/K8S:
#  CLUSTER, with the name or IP of the K8S service
#

# Remove node from cluster when stopping node
_term() {
  kill -TERM "$child" 2>/dev/null
  DATA="{\"id\":\"$NODE_ID\"}"
  curl -XDELETE http://$CLUSTER:4001/remove -d "$DATA"
}
trap _term SIGTERM

IP_ADDRESS=$(hostname --all-ip-addresses | cut -d' ' -f 1)
NODE_ID=$(hostname)

# Default CMD
if [ "$1" = 'leader' ]; then
  # CMD
  gosu nobody /usr/local/bin/rqlited -node-id "$NODE_ID" -http-addr $IP_ADDRESS:4001 -raft-addr $IP_ADDRESS:4002 /tmp/rqlite.db &
  child=$!
  wait "$child"
elif [ "$1" = 'node' ]; then
  # CMD
  gosu nobody /usr/local/bin/rqlited -node-id "$NODE_ID" -http-addr $IP_ADDRESS:4001 -raft-addr $IP_ADDRESS:4002 -join http://$CLUSTER:4001 /tmp/rqlite.db &
  child=$!
  wait "$child"
else
  # CMD override (used for debug)
  exec "$@"
fi

