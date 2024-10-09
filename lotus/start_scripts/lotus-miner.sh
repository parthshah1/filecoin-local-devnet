#!/bin/bash

# Function to check the health of the Lotus node by making an RPC call
check_health() {
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://lotus:1234/rpc/v1 -H 'Content-Type: application/json' -d '{
        "jsonrpc": "2.0",
        "method": "Filecoin.ChainHead",
        "params": [],
        "id": 1
    }')
    
    if [ "$response" -eq 200 ]; then
        echo "Health check passed."
        return 0 # Success
    else
        echo "Health check failed with response code: $response. Retrying..."
        return 1 # Failure
    fi
}

# Loop until the health check passes
until check_health; do
    sleep 5 # Wait for 5 seconds before retrying
done

# Once the Lotus node is confirmed to be up, proceed with the miner setup
export DRAND_CHAIN_INFO=$(cat ${LOTUS_DATA_DIR}/chain_info)
lotus-miner --version
lotus wallet import --as-default /root/.genesis-sectors/pre-seal-t01000.key
lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=/root/.genesis-sectors --pre-sealed-metadata=/root/.genesis-sectors/pre-seal-t01000.json --nosync
echo "RUNINGGggggggggggggggggggggggggggggg"
lotus-miner run --nosync &
lotus-miner wait-api
echo "lotus-miner running"
sleep infinity