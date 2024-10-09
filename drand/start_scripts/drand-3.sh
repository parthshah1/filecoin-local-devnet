#!/bin/bash

# Wait a bit longer to ensure leader and second node are up
sleep 6

# Generate the key pair for the third node
drand generate-keypair --scheme bls-unchained-g1-rfc9380 --id default 10.20.20.23:8080 

# Start the drand daemon for the third node
drand start --private-listen 10.20.20.23:8080 --control 127.0.0.1:8888 --public-listen 0.0.0.0:80 &


echo "SETUP: Node 3 ready, joining DKG as a follower"

# Join the DKG process initiated by the leader
sleep 13
drand dkg join --control 8888 
sleep infinity