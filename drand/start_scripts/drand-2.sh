#!/bin/bash

# Wait a few seconds to ensure the leader is up first
sleep 5

# Generate the key pair for the second node
drand generate-keypair --scheme bls-unchained-g1-rfc9380 --tls-disable --id default 10.20.20.22:8080 

# Start the drand daemon for the second node
drand start --private-listen 10.20.20.22:8080 --control 127.0.0.1:8888 --public-listen 0.0.0.0:80 &


echo "SETUP: Node 2 ready, joining DKG as a follower"

# Join the DKG process initiated by the leader
sleep 12
drand dkg join --control 8888 
sleep infinity