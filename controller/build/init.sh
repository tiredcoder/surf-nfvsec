#!/usr/bin/env bash
#
# init.sh - Container init script: Start the NFV controller.
# Author: Rik Janssen <Rik.Janssen@os3.nl>
# Project: UvA, SNE/OS3, RP2
#
# Requires that the following env variables have been set via Docker/K8S:
#  DBSERV, with the name or IP of the K8S service providing the database cluster.
#

# Default CMD
if [ "$1" = 'default' ]; then
  mkdir -p /root/.ssh
  ssh-keyscan "$LB" > ~/.ssh/known_hosts

  # CMD
  gosu root /surf/app/nfv_controller.py
else
  # CMD override (used for debug)
  exec "$@"
fi

