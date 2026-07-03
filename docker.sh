#!/bin/bash

set -e

# Must run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


# change docker root
mkdir -p /etc/docker /data/docker
cat >/etc/docker/daemon.json <<EOL
{
  "data-root": "/data/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file":"5"
  }
}
EOL

# Install docker
wget -qO- get.docker.com | bash
sudo systemctl enable docker
