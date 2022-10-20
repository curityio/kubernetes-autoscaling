#!/bin/bash

#####################################################################################################
# Installs a Custom Metrics API via the Prometheus Adapter project, as documented in the below guides
# - https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/walkthrough.md
# - https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/deploy/README.md
#####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

cd ..
mkdir -p download
rm -rf download/prometheus-adapter
cd download

#
# Get resources and create the namespace
#
git clone https://github.com/kubernetes-sigs/prometheus-adapter
if [ $? -ne 0 ]; then
  echo 'Problem encountered downloading custom metrics'
  exit 1
fi
kubectl create namespace custom-metrics 2>/dev/null

#
# Copy in the configmap with custom metrics
#
cd prometheus-adapter/deploy
cp ../resources/custom-metrics-config-map.yaml ./manifests/

#
# Create a default version of the cm-adapter-serving-certs secret and the serving certificates
#
export PURPOSE=serving
openssl req -x509 -sha256 -new -nodes -days 365 -newkey rsa:2048 -keyout ${PURPOSE}-ca.key -out ${PURPOSE}-ca.crt -subj "/CN=ca"
echo '{"signing":{"default":{"expiry":"43800h","usages":["signing","key encipherment","'${PURPOSE}'"]}}}' > "${PURPOSE}-ca-config.json"
kubectl -n custom-metrics delete secret cm-adapter-serving-certs 2>/dev/null
kubectl -n custom-metrics create secret tls cm-adapter-serving-certs --cert=./serving-ca.crt --key=./serving-ca.key

#
# Also replace the certificate file names, which by default seem to be generated incorrectly
# https://github.com/kubernetes-sigs/prometheus-adapter/issues/57
#
sed -i '' 's/serving.crt/tls.crt/g' ./manifests/custom-metrics-apiserver-deployment.yaml
sed -i '' 's/serving.key/tls.key/g' ./manifests/custom-metrics-apiserver-deployment.yaml

#
# Use the prometheus URL from the monitoring namespace
#
INVALID_URL=prometheus.prom.svc
VALID_URL=prometheus-k8s.monitoring.svc.cluster.local
sed -i '' "s/$INVALID_URL/$VALID_URL/g" ./manifests/custom-metrics-apiserver-deployment.yaml

#
# Also use a recent release for the Docker image
#
INVALID_IMAGE='gcr.io\/k8s-staging-prometheus-adapter-amd64'
VALID_IMAGE='gcr.io\/k8s-staging-prometheus-adapter\/prometheus-adapter:v0.9.0'
sed -i '' "s/$INVALID_IMAGE/$VALID_IMAGE/g" ./manifests/custom-metrics-apiserver-deployment.yaml

#
# Then deploy the custom metrics system
#
kubectl apply -f manifests/
if [ $? -ne 0 ]; then
  echo 'Problem encountered deploying the Custom Metrics API'
  exit 1
fi
