#!/bin/bash
sleep 60
while true; do
    # Extract the first element from the JSON array and store it in a variable
    curl 10.20.20.21/info 
    chain_1=$(curl 10.20.20.21/info | jq -r '.[]')
    echo "Chain Value: $chain_1"
    # Check if chain is not empty
    if [ -n "$chain_1" ] ; then
        echo "Received data: $chain_1"
        break
    else
        echo "No data received, retrying..."
    fi

    # Optionally, sleep for a short period to avoid spamming the server
    sleep 1s
done

curl 10.20.20.21/$chain_1/info | jq -c > /opt/lotus_transformed/customer/devgen/chain_info
cat /opt/lotus_transformed/customer/devgen/chain_info
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
