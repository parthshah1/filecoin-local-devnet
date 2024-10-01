#!/bin/bash
sleep 150


if [ -z "$FOREST_DATA_DIR" ]; then
    echo "Error: FOREST_DATA_DIR is not set."
    exit 1
fi


if [ ! -f "${FOREST_DATA_DIR}/token.jwt" ]; then
    echo "Error: Token file not found at ${FOREST_DATA_DIR}/token.jwt."
    exit 1
fi


export TOKEN=$(cat ${FOREST_DATA_DIR}/token.jwt)
if [ -z "$TOKEN" ]; then
    echo "Error: TOKEN is empty."
    exit 1
fi

if [ -z "$FOREST_RPC_PORT" ]; then
    echo "Error: FOREST_RPC_PORT is not set."
    exit 1
fi

export FULLNODE_API_INFO=${TOKEN}:/dns/forest/tcp/${FOREST_RPC_PORT}/http

echo "FOREST_DATA_DIR: $FOREST_DATA_DIR"
echo "TOKEN: $TOKEN"
echo "FULLNODE_API_INFO: $FULLNODE_API_INFO"

forest-wallet --remote-wallet import ${LOTUS_DATA_DIR}/key || true
echo "Done"
forest-cli net connect /dns/lotus-node/tcp/${LOTUS_P2P_PORT}/p2p/$(cat ${LOTUS_DATA_DIR}/p2pID) 
forest-cli info show
forest-cli --token $TOKEN auth create-token --perm admin



echo "Done"