#!/bin/bash
while true; do
    # Extract the first element from the JSON array and store it in a variable
    chain_1=$(curl 10.20.20.21/chains | jq -r '.[]')
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

curl 10.20.20.21/$chain_1/info | jq -c > /go/lotus-local-net/devgen/chain_info
export DRAND_CHAIN_INFO=/go/lotus-local-net/devgen/chain_info

/go/lotus-local-net/./lotus daemon --lotus-make-genesis=/go/lotus-local-net/devgen/devgen.car --genesis-template=/go/lotus-local-net/lotus-local-net/localnet.json --bootstrap=false &
/go/lotus-local-net/./lotus wait-api
/go/lotus-local-net/./lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key
/go/lotus-local-net/./lotus net listen > /go/lotus-local-net/devgen/ipv4addr
/go/lotus-local-net/./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync
/go/lotus-local-net/./lotus-miner run --nosync 
