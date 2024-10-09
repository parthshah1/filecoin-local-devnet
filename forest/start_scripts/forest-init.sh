#!/bin/bash
# Enable strict mode to catch errors and undefined variables
set -euo pipefail
sleep 45

# Function to check if Lotus RPC is running and block height is greater than 10
check_lotus_health() {
    response=$(curl -s -X POST http://lotus:1234/rpc/v1 -H 'Content-Type: application/json' -d '{
        "jsonrpc": "2.0",
        "method": "Filecoin.ChainHead",
        "params": [],
        "id": 1
    }')

    # Extract the block height using grep and cut (without jq)
    block_height=$(echo "$response" | grep -o '"Height":[0-9]*' | head -1 | cut -d':' -f2)

    # Ensure block_height is not empty and is a valid number
    if [[ -n "$block_height" && "$block_height" =~ ^[0-9]+$ ]]; then
        if [ "$block_height" -gt 8 ]; then
            echo "Lotus block height is greater than 8. Current height: $block_height"
            return 0
        else
            echo "Lotus block height is $block_height. Waiting for height > 8..."
            return 1
        fi
    else
        echo "Failed to retrieve block height. Response: $response"
        return 1
    fi
}

# Wait until Lotus is running and block height > 10
until check_lotus_health; do
    sleep 5
done

# Fetch and save DRAND chain information
curl "http://drand-1/info" | jq -c > chain_info
export DRAND_CHAIN_INFO=chain_info
cat $DRAND_CHAIN_INFO

# Extract network name from localnet.json and set it as an environment variable
export NETWORK_NAME=$(grep -o "localnet.*" "${LOTUS_DATA_DIR}/localnet.json" | tr -d '",' )

# Copy the forest configuration template and update it with the network name
cp /forest/forest_config.toml.tpl "${FOREST_DATA_DIR}/forest_config.toml"
echo "name = \"${NETWORK_NAME}\"" >> "${FOREST_DATA_DIR}/forest_config.toml"

# Load the token and set the full node API information
cat ${FOREST_DATA_DIR}/forest_config.toml

# Start the forest service with the specified configuration
forest --genesis "${LOTUS_DATA_DIR}/devgen.car" \
       --config "${FOREST_DATA_DIR}/forest_config.toml" \
       --save-token "${FOREST_DATA_DIR}/token.jwt" \
       --rpc-address 10.20.20.26:"${FOREST_RPC_PORT}" \
       --p2p-listen-address /ip4/10.20.20.26/tcp/${FOREST_P2P_PORT} \
       --skip-load-actors \
       --healthcheck-address 10.20.20.26:${FOREST_HEALTHZ_PORT}

sleep infinity
