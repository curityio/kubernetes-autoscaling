#!/bin/bash

###################################################################################################
# Redeploys the Service Monitor to tell Prometheus how to contact Identity Server metrics endpoints
###################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Copy updated configuration to the adapter folder
#
cd ../resources
kubectl delete -f curity-service-monitor.yaml 2>/dev/null
kubectl apply -f curity-service-monitor.yaml
