#!/usr/bin/bash
#
# SURF NFV Controller
# Infra (data plane) interface
#
# Author: Rik Janssen <Rik.Janssen@os3.nl>
# Project: UvA, SNE/OS3, RP2
# Version: 1.1, Mar. 2019
#
# env var 'II' has to be set to the infra interface's name/IP
#
# Note: 
#  - The infra is a CentOS 7 QEMU/KVM hypervisor router (using Linux netfilter) running the K8S cluster.
#  - Function chaining and load balancing currently isn't implemented; rules are created using iptables with the 'TEE' target of the mangle table, which clones packets.
#
CMD="$1"
EDU="$2"
VNF="$3"

if [ "$CMD" = 'add' ]; then
    ssh -i /etc/secret-volume/ssh-privatekey root@"$II" "iptables -t mangle -A PREROUTING -s $EDU -j TEE --gateway $VNF"
elif [ "$CMD" = 'del' ]; then
    ssh -i /etc/secret-volume/ssh-privatekey root@"$II" "iptables -t mangle -D PREROUTING -s $EDU -j TEE --gateway $VNF"
fi
