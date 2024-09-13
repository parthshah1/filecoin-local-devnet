#!/bin/bash

# Generate the key pair for the leader node
drand generate-keypair --scheme bls-unchained-g1-rfc9380 --id default 10.20.20.21:8080 

# Start the drand daemon for the leader node
drand start --id default --private-listen 10.20.20.21:8080 --control 127.0.0.1:8888 --public-listen 0.0.0.0:80  &

sleep 10
echo "SETUP: Node 1 ready, initializing DKG as leader"

# Initialize the DKG process as the leader
#DRAND_SHARE_SECRET=mysecretmysecretmysecretmysecret drand share --id default --leader --nodes 3 --threshold 2 --period 30s --scheme bls-unchained-g1-rfc9380 
#drand dkg init --id default --leader --nodes 3 --threshold 2 --period 30s --control 127.0.0.1:8888 --scheme bls-unchained-g1-rfc9380 
drand dkg generate-proposal  --joiner 10.20.20.21:8080 --joiner 10.20.20.22:8080 --joiner 10.20.20.23:8080  --out proposal.toml
drand dkg init --proposal ./proposal.toml --threshold 2 --period 3s --scheme bls-unchained-g1-rfc9380 --catchup-period 0s --genesis-delay 30s
sleep 20
drand dkg execute 
sleep infinity
