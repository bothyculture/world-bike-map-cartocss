#!/bin/bash

set -euo pipefail


docker compose down
sudo rm -rf /osm-data/*
docker compose build
docker compose up import
docker compose up light dark