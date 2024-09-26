#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

which prometheus &>/dev/null || {
  apt-get update
  apt-get install --no-install-recommends -y curl wget tar

  # check arch
  if [[ "`uname -m`" =~ "arm" ]]; then
    ARCH=arm
  elif [[ "`uname -m`" == "aarch64" ]]; then
    ARCH=arm64
  else
    ARCH=amd64
  fi

  cd /usr/local


  wget -q https://github.com/prometheus/prometheus/releases/download/v3.0.0-beta.0/prometheus-3.0.0-beta.0.linux-amd64.tar.gz
  tar zxvf prometheus-3.0.0-beta.0.linux-amd64.tar.gz

  ln -s /usr/local/prometheus-3.0.0-beta.0.linux-amd64/prometheus /usr/local/bin/prometheus
  ln -s /usr/local/prometheus-3.0.0-beta.0.linux-amd64/promtool /usr/local/bin/promtool
}

# create directory structure
mkdir -p /etc/prometheus
curl -sL -o /etc/prometheus/prometheus.yml https://raw.githubusercontent.com/andrewpopa/bash-provisioning/main/prometheus/prometheus.yml
curl -sL -o /etc/systemd/system/prometheus.service https://raw.githubusercontent.com/andrewpopa/bash-provisioning/main/prometheus/prometheus.service

systemctl enable prometheus.service
systemctl start prometheus.service