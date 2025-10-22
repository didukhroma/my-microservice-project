#!/bin/bash

# Debian and Ubuntu

export DEBIAN_FRONTEND=noninteractive

# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin python3 python3-pip"

for i in $PACKAGES; do
	if dpkg -l | grep $i > /dev/null 2>&1; then
		echo "${i} package already installed"
	else
		apt-get install \
			-y $i \
			--no-install-recommends
	fi
done

if pip list Django; then
	echo "Django is already installed"
else
	pip install Django
fi

