#!/bin/bash
file_to_check="/opt/lotus_transformed/customer/devgen/devgen.car"
while [ ! -f "$file_to_check" ]; do
    echo "Waiting for $file_to_check to be created..."
    sleep 5
done

chain_1=$(curl 10.20.20.21/chains | jq -r '.[]')
curl 10.20.20.21/$chain_1/info | jq -c  > /opt/lotus_transformed/customer/devgen/chain_info
export DRAND_CHAIN_INFO=/opt/lotus_transformed/customer/devgen/chain_info

./lotus daemon  --genesis=/opt/lotus_transformed/customer/devgen/devgen.car --bootstrap=false --config=/opt/lotus_transformed/customer/devgen/config.toml &
./lotus wallet import --as-default /root/.genesis-sectors/pre-seal-t01001.key
./lotus-miner init --genesis-miner --actor=t01001 --sector-size=2KiB --pre-sealed-sectors=/root/.genesis-sectors --pre-sealed-metadata=/root/.genesis-sectors/pre-seal-t01001.json --nosync
./lotus-miner run --nosync 

file_to_check="/opt/lotus_transformed/customer/devgen/ipv4addr"
while [ ! -f "$file_to_check" ]; do
    echo "Waiting for $file_to_check to be created..."
    sleep 5
done
ipv4addr=$(head -n 1 $file_to_check)
echo $ipv4addr
./lotus net connect $ipv4addr
./lotus sync status

./lotus auth create-token --perm admin > /opt/lotus_transformed/customer/devgen/lotus-2-token.txt

sleep infinity
