#!/bin/bash
# Function to check if the service is healthy
url="http://drand-1/info"  
check_service_health() {
    response=$(curl -s --head "$url")  # Store the response
    if echo "$response" | grep "200 OK" > /dev/null; then
        echo "Drand is healthy. Fetching chain_info from Drand."
        return 0
    else
        echo "Drand is not healthy."
        return 1
    fi
}

# Wait for the service to be healthy
until check_service_health; do
    echo "Waiting for drand to be healthy..."
    sleep 5
done

while true; do
    curl "$url" | jq -c > ${LOTUS_DATA_DIR}/chain_info
    if [ $(wc -c < ${LOTUS_DATA_DIR}/chain_info) -gt 0 ]; then
        break
    fi
    echo "Waiting for DRAND to perform DKG"
    sleep 1
done
export DRAND_CHAIN_INFO=${LOTUS_DATA_DIR}/chain_info

# Copying the 
cp /root/.genesis-sectors/pre-seal-t01000.key ${LOTUS_DATA_DIR}/key
cp /lotus/config.toml "${LOTUS_DATA_DIR}/config.toml"
cat localnet.json | jq -r '.NetworkName' > ${LOTUS_DATA_DIR}/network_name
cp localnet.json ${LOTUS_DATA_DIR}/localnet.json
lotus daemon --lotus-make-genesis=${LOTUS_DATA_DIR}/devgen.car --genesis-template=localnet.json --bootstrap=false --config=${LOTUS_DATA_DIR}/config.toml&
lotus wait-api
echo "API running."
lotus net listen > ${LOTUS_DATA_DIR}/ipv4addr
lotus net id > ${LOTUS_DATA_DIR}/p2pID
echo Finished waiting for API, importing wallet now.
lotus auth create-token --perm admin > ${LOTUS_DATA_DIR}/jwt
echo "JWT created"
sleep infinity

