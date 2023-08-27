#!/bin/sh

# -e to exit immediately if a command exits with a non-zero status
# -u to treat unset variables as an error when substituting
set -eu

# Initialize the swarm.
docker swarm init \
    --advertise-addr $(tailscale ip -4) \
    --data-path-addr $(tailscale ip -4)

# Delete the ingress netowrk.
docker network rm ingress </bin/yes

# Re-create the ingress network, matching the Tailscale MTU.
docker network create \
    -d overlay \
    --ingress \
    --opt com.docker.network.driver.mtu=1280 \
    ingress
