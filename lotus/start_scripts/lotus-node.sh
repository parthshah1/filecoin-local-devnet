#!/bin/bash
sleep 60

curl 10.20.20.21/info | jq -c > chain_info
export DRAND_CHAIN_INFO=chain_info
lotus --version
cp /root/.genesis-sectors/pre-seal-t01000.key ${LOTUS_DATA_DIR}/key
cp /lotus/config.toml "${LOTUS_DATA_DIR}/config.toml"
cat localnet.json | jq -r '.NetworkName' > ${LOTUS_DATA_DIR}/network_name
cp localnet.json ${LOTUS_DATA_DIR}/localnet.json
lotus daemon --lotus-make-genesis=${LOTUS_DATA_DIR}/devgen.car --genesis-template=localnet.json --bootstrap=false --config=${LOTUS_DATA_DIR}/config.toml&
lotus wait-api

echo Finished waiting for API, importing wallet now.

lotus net listen > ${LOTUS_DATA_DIR}/ipv4addr
lotus net id > ${LOTUS_DATA_DIR}/p2pID
echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
ls -l ${LOTUS_DATA_DIR}
lotus auth create-token --perm admin > ${LOTUS_DATA_DIR}/jwt
sleep infinity

