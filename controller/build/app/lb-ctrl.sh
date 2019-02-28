#!/usr/bin/bash
#
# SURF NFV Controller
# Load balancer interface
#
# Author: Rik Janssen <Rik.Janssen@os3.nl>
# Project: UvA, SNE/OS3, RP2
# Version: 1.0, Feb. 2019
#
# env var 'LB' has to be set to the load balancer's name/IP
#
# Note: 
#  - The load balancer is a CentOS 7 QEMU/KVM hypervisor router (using Linux netfilter) running the K8S cluster.
#  - Function chaining and load balancing currently isn't implemented; rules are created using iptables with the 'TEE' target of the mangle table, which clones packets.
#
CMD="$1"
EDU="$2"
VNF="$3"

if [ "$CMD" = 'add' ]; then
    ssh -i /etc/secret-volume/ssh-privatekey root@"$LB" "iptables -t mangle -A PREROUTING -s $EDU -j TEE --gateway $VNF"
elif [ "$CMD" = 'del' ]; then
    ssh -i /etc/secret-volume/ssh-privatekey root@"$LB" "iptables -t mangle -D PREROUTING -s $EDU -j TEE --gateway $VNF"
fi
