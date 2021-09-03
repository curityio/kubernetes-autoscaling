#!/bin/bash

###################################################################################
# Sends a number of requests to the Curity Identity Server to generate some metrics
###################################################################################

#
# First create the client if required
#
curl -S -s -i -k -u admin:Password1 -X POST https://admin.curity.local/admin/api/restconf/data/base:profiles/base:profile=token-service,oauth-service/base:settings/profile-oauth:authorization-server/profile-oauth:client-store/profile-oauth:config-backed \
-H "Content-Type: application/yang-data+xml" \
-o /dev/null \
-d@- <<'EOF'
<client>
<id>metrics-test-client</id>
<client-name>metrics-test-client</client-name>
<description>A client to generate some metrics for auto scaling</description>
<secret>Password1</secret>
<scope>read</scope>
<capabilities>
<client-credentials/>
</capabilities>
<use-pairwise-subject-identifiers>
<sector-identifier>metrics-test-client</sector-identifier>
</use-pairwise-subject-identifiers>
</client>
EOF

#
# Now run a basic load test to fire 100 client credentials requests, to generate some metrics
#
NUM_REQUESTS=100
CURRENT=0
while [ $CURRENT -ne $NUM_REQUESTS ];
do
    CURRENT=$(($CURRENT+1))
    TOKEN=$(curl -s -k -X POST https://login.curity.local/oauth/v2/oauth-token \
        -u 'metrics-test-client:Password1' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -d 'grant_type=client_credentials' \
        -d 'scope=read' | jq -r .access_token)
    echo "OAuth request $CURRENT: $TOKEN"
done

#
# Get some metrics by calling Identity Server nodes directly
#
for POD in `kubectl get pods -o=name | grep curity-idsvr-runtime`
do
  echo -e "\033[1;32m$POD metrics:\033[0m"
   kubectl exec -it $POD -- bash -c 'curl http://localhost:4466/metrics' | grep idsvr_http_server_request
done
