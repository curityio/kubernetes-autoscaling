#!/bin/bash

#####################################################
# Cleans up all custom resources previously installed
#####################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Delete the service monitor
#
kubectl delete servicemonitor/curity-idsvr-runtime

#
# Uninstall the custom metrics API
#
cd ../download/prometheus-adapter/deploy
kubectl delete -f manifests/
kubectl delete namespace custom-metrics

#
# Uninstall the Prometheus system
#
cd ../../kube-prometheus
kubectl delete -f manifests/
kubectl delete -f manifests/setup

#
# Remove the client used in the generate metrics script
#
curl -S -s -i -k -u admin:Password1 -X DELETE -o /dev/null \
https://admin.curity.local/admin/api/restconf/data/base:profiles/base:profile=token-service,oauth-service/base:settings/profile-oauth:authorization-server/profile-oauth:client-store/profile-oauth:config-backed/profile-oauth:client=metrics-test-client
