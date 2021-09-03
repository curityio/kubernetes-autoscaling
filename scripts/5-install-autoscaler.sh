#!/bin/bash

########################################################################################
# Redeploys the Custom Metrics API with updated configuration containing the custom rate
########################################################################################

#
# Deploy the custom metrics by which we will autoscale
#
cd ../resources
cp custom-metrics-config-map.yaml ../tmp/prometheus-adapter/deploy/manifests/
cd ../tmp/prometheus-adapter/deploy

#
# Redeploy the entire Custom Metrics API
#
kubectl delete -f manifests/
kubectl apply -f manifests/

#
# Wait for it to become available
#
echo 'Waiting for metrics system to come up ...'
API_PATH='/apis/external.metrics.k8s.io/v1beta1/namespaces/default/idsvr_http_server_request_rate'
API_DATA=$(kubectl get --raw $API_PATH 2>/dev/null)
while [ $? != 0 ];
do 
  sleep 2
  API_DATA=$(kubectl get --raw $API_PATH 2>/dev/null)
done

#
# Output the aggregated custom metric across all containers
#
echo $API_DATA | jq

#
# Then redeploy the horizontal pod autoscaler, which references the above aggregate value
#
cd ../../../resources
kubectl delete -f curity-autoscaler.yaml 2>/dev/null
kubectl apply -f curity-autoscaler.yaml
