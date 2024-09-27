#!/bin/bash
sleep 60
curl 10.20.20.21/info | jq -c > /opt/lotus_transformed/customer/devgen/chain_info
export DRAND_CHAIN_INFO=/opt/lotus_transformed/customer/devgen/chain_info

./lotus daemon --lotus-make-genesis=/opt/lotus_transformed/customer/devgen/devgen.car --genesis-template=/opt/lotus_transformed/customer/localnet.json --bootstrap=false --config=/opt/lotus_transformed/customer/devgen/config.toml &
cp /opt/lotus_transformed/customer/devgen/devgen.car /opt/lotus_transformed/customer/shared/devgen.car
cat /opt/lotus_transformed/customer/localnet.json | jq -r '.NetworkName' > /opt/lotus_transformed/customer/shared/network_name
ls -l /opt/lotus_transformed/customer/shared
# Write the network_name to shared
# Check if the file was written successfully

if [ -f /opt/lotus_transformed/customer/shared/network_name ]; then
    echo "NetworkName successfully written to shared folder."
else
    echo "Failed to write NetworkName to shared folder!"
fi

echo Waiting for API

./lotus wait-api

echo Finished waiting for API, importing wallet now.

./lotus wallet import --as-default /root/.genesis-sectors/pre-seal-t01000.key
./lotus net listen > /opt/lotus_transformed/customer/devgen/ipv4addr
echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
ls -l /opt/lotus_transformed/customer/shared
# Creating a token in the common volume mount
./lotus auth create-token --perm admin > /opt/lotus_transformed/customer/shared/jwt 
./lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key
./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync
./lotus-miner run --nosync 
