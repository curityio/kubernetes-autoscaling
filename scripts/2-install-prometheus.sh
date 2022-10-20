#!/bin/bash

###################################################################################################
# Installs the Prometheus system, which will later call the Curity Identity Server metrics endpoint
###################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

cd ..
mkdir -p download
rm -rf download/kube-prometheus
cd download

git clone https://github.com/prometheus-operator/kube-prometheus
if [ $? -ne 0 ]; then
  echo 'Problem encountered downloading Prometheus'
  exit 1
fi

cd kube-prometheus
kubectl apply --server-side -f manifests/setup
if [ $? -ne 0 ]; then
  echo 'Problem encountered setting up the Prometheus operator'
  exit 1
fi

kubectl apply -f manifests/
if [ $? -ne 0 ]; then
  echo 'Problem encountered deploying Prometheus'
  exit 1
fi
