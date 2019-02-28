#!/usr/bin/env bash
#
# K8S deploy script
#

# apply or delete
CMD="$1"

K8S_NODE="<IPv4 address>"

echo -e "Starting k8s deployment script!\n"
if [ "$CMD" = 'apply' ]; then
  echo -e "Deploying...\n"

  echo "rqlite database cluster..."
  kubectl $CMD -f database/k8s-rqlite-service.yaml
  kubectl $CMD -f database/k8s-rqlite-leader.yaml
  sleep 20
  kubectl $CMD -f database/k8s-rqlite-node.yaml

  echo
  sleep 20

  echo "SURF NFV Controller..."
  kubectl $CMD -f controller/k8s-nfv-controller.yaml

  echo
  sleep 20

  echo "Init DB"
  curl -XPUT http://$K8S_NODE:30007/api/db/init
  sleep 3

  echo -e "\n\nVNF tcpdump..."
  kubectl $CMD -f vnf/k8s-vnf-tcpdump.yaml

  echo -e "\nInserting test values..."

  echo "Inserting edu"
  curl --header "Content-Type: application/json" \
       --request PUT \
       --data '{"name":"UvA","ip":"10.200.0.11"}' \
       http://$K8S_NODE:30007/api/edu

  curl --header "Content-Type: application/json" \
       --request PUT \
       --data '{"name":"ROC","ip":"10.200.0.12"}' \
       http://$K8S_NODE:30007/api/edu

  curl --header "Content-Type: application/json" \
       --request PUT \
       --data '{"name":"HBO","ip":"10.200.0.13"}' \
       http://$K8S_NODE:30007/api/edu

  echo -e "\n\nDB Content:"
  echo "edu:"
  curl http://$K8S_NODE:30007/api/edu

  sleep 30
  echo -e "\nvnf:"
  curl http://$K8S_NODE:30007/api/vnf

  echo -e "\n\nPlease insert rule and generate traffic."

elif [ "$CMD" = 'delete' ]; then
  echo -e "Deleting deployment...\n"
  kubectl $CMD -f vnf/k8s-vnf-tcpdump.yaml
  kubectl $CMD -f controller/k8s-nfv-controller.yaml
  kubectl $CMD -f database/k8s-rqlite-node.yaml
  kubectl $CMD -f database/k8s-rqlite-leader.yaml
  kubectl $CMD -f database/k8s-rqlite-service.yaml
fi

echo "Done!"

