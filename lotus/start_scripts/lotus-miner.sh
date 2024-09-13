#!/bin/bash

#echo "lotus-1 is fully functional."
#while true; do
#    # Extract the first element from the JSON array and store it in a variable
#    chain_1=$(curl 10.20.20.21/info | jq -r '.[]')
#    # Check if chain is not empty
#    if [ -n "$chain_1" ] ; then
#        echo "Received data: $chain_1"
#        break
#    else
#        echo "No data received, retrying..."
#    fi
#
#    # Optionally, sleep for a short period to avoid spamming the server
#    sleep 1s
#done
sleep 90
export DRAND_CHAIN_INFO=/go/lotus-local-net/devgen/chain_info

