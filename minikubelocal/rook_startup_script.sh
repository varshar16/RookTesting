#!/bin/bash -e

~/minikube_re.sh up ceph
cd ~/go/src/github.com/rook/rook/cluster/examples/kubernetes/ceph

kubectl create -f crds.yaml -f common.yaml -f operator.yaml

kubectl get pods --all-namespaces

echo "Wait for all pods to come up"
sleep 30

kubectl get pods --all-namespaces

echo "Creating ceph cluster"
kubectl create -f cluster-test.yaml
sleep 140
echo "Creating tool box"
kubectl create -f toolbox.yaml

sleep 140

kubectl get pods --all-namespaces
#../../../../tests/scripts/minikube.sh clean
