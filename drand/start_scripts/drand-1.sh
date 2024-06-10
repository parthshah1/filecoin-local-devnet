#!/bin/bash
drand generate-keypair --tls-disable --id default 10.20.20.21:8080;
drand start --tls-disable --private-listen 10.20.20.21:8080 --control 8888 --public-listen 0.0.0.0:80 &
until [[ "$(drand util check --tls-disable 10.20.20.21:8080)" =~ "answers correctly" ]]
    do
        sleep 1
    done
echo "SETUP: starting as leader"

DRAND_SHARE_SECRET=mysecretmysecretmysecretmysecret drand share --id default --leader --nodes 3 --threshold 3 --period 30s --tls-disable
sleep infinity