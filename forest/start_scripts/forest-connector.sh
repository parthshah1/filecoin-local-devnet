#!/bin/bash
sleep 50

# Function to check if the Forest service returns a 200 OK status
check_forest_health() {
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://10.20.20.26:2347/healthz?verbose" -H 'Content-Type: application/json')

    if [ "$response_code" -eq 405 ]; then
        echo "Forest service is healthy (200 OK)."
        sleep 10
        return 0
    else
        echo "Forest service is unhealthy (Response code: $response_code). Retrying..."
        return 1
    fi
}

# Wait until the Forest service returns 200 OK
until check_forest_health; do
    sleep 5
done

# Proceed with the connector script after the health check passes
export TOKEN=$(cat ${FOREST_DATA_DIR}/token.jwt)
export FULLNODE_API_INFO=$TOKEN:/dns/forest/tcp/${FOREST_RPC_PORT}/http
echo "FULLNODE_API_INFO: $FULLNODE_API_INFO"

# Import wallet and connect to Lotus
forest-wallet --remote-wallet import ${LOTUS_DATA_DIR}/key
forest-cli net connect /ip4/10.20.20.24/tcp/${LOTUS_P2P_PORT}/p2p/$(cat ${LOTUS_DATA_DIR}/p2pID)
forest-cli sync wait

echo "Forest connector setup is complete."
