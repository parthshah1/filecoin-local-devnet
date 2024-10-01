#!/bin/bash
sleep 200
set -euxo pipefail
export TOKEN=$(cat ${FOREST_DATA_DIR}/token.jwt)
export FULLNODE_API_INFO=$TOKEN:/dns/forest/tcp/${FOREST_RPC_PORT}/http
echo "FULLNODE_API_INFO: $FULLNODE_API_INFO"

forest-wallet --remote-wallet import ${LOTUS_DATA_DIR}/key 
forest-wallet new bls
forest-cli net connect /ip4/10.20.20.24/tcp/${LOTUS_P2P_PORT}/p2p/$(cat ${LOTUS_DATA_DIR}/p2pID) 
forest-cli sync wait
echo "Done"
