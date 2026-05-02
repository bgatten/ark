#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install dkms

sudo apt-get install htop

sudo snap install foxglove-studio