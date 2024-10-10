#!/bin/bash

# Wait until the leader is up
tries=10
echo "drand-3: waiting for drand-1 to be up..."
while [ "$tries" -gt 0 ]; do
    drand util check 10.20.20.21:8080
    if [ $? -eq 0 ]
    then
        echo "drand-3: drand-1 is up!"
        break
    fi
    tries=$(( tries - 1 ))
    echo "drand-3: $tries connection attempts remaining..."
    sleep 1
done

if [ "$tries" -eq 0 ]; then
    echo "drand-3: failed to find drand-1"
    exit 1
fi

# Generate the key pair for the third node
drand generate-keypair --scheme bls-unchained-g1-rfc9380 --id default 10.20.20.23:8080 

# Start the drand daemon for the third node
drand start --private-listen 10.20.20.23:8080 --control 127.0.0.1:8888 --public-listen 0.0.0.0:80 &

echo "SETUP: Node 3 ready, joining DKG as a follower"

tries=10
while [ "$tries" -gt 0 ]; do
    echo "drand-3: checking dkg status"
    lines=$(drand dkg status --control 8888 | wc -l)
    if [ "$lines" -gt 10 ]; then
        echo "drand-3: dkg status up"
        break
    fi
    tries=$(( tries - 1 ))
    echo "drand-3: $tries connection attempts remaining..."
    sleep 1
done

if [ "$tries" -eq 0 ]; then
    echo "drand-3: dkg status never good"
    exit 1
fi

# Join the DKG process initiated by the leader
drand dkg join --control 8888 
sleep infinity
