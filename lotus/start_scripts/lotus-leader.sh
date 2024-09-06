#!/bin/bash
sleep 60
curl 10.20.20.21/info | jq -c > /opt/lotus_transformed/customer/devgen/chain_info
export DRAND_CHAIN_INFO=/opt/lotus_transformed/customer/devgen/chain_info

./lotus daemon --lotus-make-genesis=/opt/lotus_transformed/customer/devgen/devgen.car --genesis-template=/opt/lotus_transformed/customer/localnet.json --bootstrap=false --config=/opt/lotus_transformed/customer/devgen/config.toml &

echo Waiting for API

./lotus wait-api

echo Finished waiting for API, importing wallet now.

./lotus wallet import --as-default /root/.genesis-sectors/pre-seal-t01000.key
./lotus net listen > /opt/lotus_transformed/customer/devgen/ipv4addr

# Creating a token in the common volume mount
./lotus auth create-token --perm admin > /opt/lotus_transformed/customer/devgen/jwt

./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=/root/.genesis-sectors --pre-sealed-metadata=/root/.genesis-sectors/pre-seal-t01000.json --nosync
./lotus-miner run --nosync
