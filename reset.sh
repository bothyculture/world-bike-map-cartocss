#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <osm-pbf-file>"
    exit 1
fi

docker compose down
sudo rm -rf /osm-data/*
sudo cp "$1" ./data.osm.pbf
docker compose build
docker compose up import
docker compose up light dark