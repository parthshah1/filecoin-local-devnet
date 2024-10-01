#!/bin/bash
sleep 100
export DRAND_CHAIN_INFO=chain_info

lotus-miner --version
lotus wallet import --as-default /root/.genesis-sectors/pre-seal-t01000.key
lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=/root/.genesis-sectors --pre-sealed-metadata=/root/.genesis-sectors/pre-seal-t01000.json --nosync
echo "DONEEEEEEEEEEEEEEEEEEEEEEEE"
lotus-miner run --nosync 