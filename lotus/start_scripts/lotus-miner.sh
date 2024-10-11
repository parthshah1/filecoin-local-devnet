#!/bin/bash

sleep 15

lotus_node_ready=0
while [[ ${lotus_node_ready?} -eq 0 ]]
do
    echo "lotus-miner: checking if lotus-node is ready.."
    if [[ -e "/container_ready/lotus-node" ]]
    then
        echo "lotus-miner: lotus-node is ready!"
        echo "lotus-miner: continuing startup..."
        lotus_node_ready=1
    fi
    sleep 10
done

export DRAND_CHAIN_INFO=chain_info

lotus-miner --version
lotus wallet import --as-default ${LOTUS_DATA_DIR}/key
lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=/root/.genesis-sectors --pre-sealed-metadata=/root/.genesis-sectors/pre-seal-t01000.json --nosync
echo "lotus-miner: setup complete"
lotus-miner run --nosync