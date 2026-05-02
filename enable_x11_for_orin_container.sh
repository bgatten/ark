#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
ORIN_HOST="o1@ubuntu"
CONTAINER_NAME="orin-local"

echo ">>> Ensuring laptop X server allows connections..."
xhost +LOCAL: > /dev/null 2>&1

echo ">>> Connecting to Orin to configure DISPLAY and container X authority..."
ssh -Y $ORIN_HOST "
    echo '>>> DISPLAY on Orin:' \$DISPLAY

    echo '>>> Allowing root on Orin to use forwarded X server...'
    xhost +local:root > /dev/null 2>&1

    echo '>>> Ensuring container exists...'
    if ! docker ps -a --format '{{.Names}}' | grep -q '^$CONTAINER_NAME\$'; then
        echo 'ERROR: Container \"$CONTAINER_NAME\" not found.'
        exit 1
    fi

    echo '>>> Creating /root/.Xauthority inside container...'
    docker exec $CONTAINER_NAME sh -c 'touch /root/.Xauthority'

    echo '>>> Copying Orin host Xauthority into container...'
    docker cp \$HOME/.Xauthority $CONTAINER_NAME:/root/.Xauthority

    echo '>>> Setting DISPLAY inside container...'
    docker exec $CONTAINER_NAME sh -c \"export DISPLAY=\$DISPLAY\"

    echo '>>> Testing with xeyes...'
    if docker exec -e DISPLAY=\$DISPLAY $CONTAINER_NAME xeyes > /dev/null 2>&1; then
        echo ':: X11 forwarding to container is WORKING'
    else
        echo ':: X11 forwarding to container FAILED'
    fi
"

