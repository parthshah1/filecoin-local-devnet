#!/bin/bash
# Enable strict mode to catch errors and undefined variables
set -euo pipefail

# Wait for 120 seconds before starting the script
sleep 120

# Fetch and save DRAND chain information
curl 10.20.20.21/info | jq -c > chain_info
export DRAND_CHAIN_INFO=chain_info

# Extract network name from localnet.json and set it as an environment variable
export NETWORK_NAME=$(grep -o "localnet.*" "${LOTUS_DATA_DIR}/localnet.json" | tr -d '",' )

# Copy the forest configuration template and update it with the network name
cp /forest/forest_config.toml.tpl "${FOREST_DATA_DIR}/forest_config.toml"
echo "name = \"${NETWORK_NAME}\"" >> "${FOREST_DATA_DIR}/forest_config.toml"

# Load the token and set the full node API information
export TOKEN=$(cat ${FOREST_DATA_DIR}/token.jwt)
export FULLNODE_API_INFO=$TOKEN:/ip4/127.0.0.1/tcp/${FOREST_RPC_PORT}/http


# Start the forest service with the specified configuration
forest --genesis "${LOTUS_DATA_DIR}/devgen.car" \
       --config "${FOREST_DATA_DIR}/forest_config.toml" \
       --save-token "${FOREST_DATA_DIR}/token.jwt" \
       --rpc-address 0.0.0.0:"${FOREST_RPC_PORT}"

# Ensure the service is running by checking the sync status
forest-cli sync status 

# Keep the script running indefinitely
sleep infinity
