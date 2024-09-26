#!/usr/bin/env bash

# we want the scrip to be verbose
set -x

# install packages if not installed
which curl wget unzip jq &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install --no-install-recommends -y curl wget unzip jq
}

# check if consul is installed
# if not, download and configure service
which consul &>/dev/null || {
  pushd /var/tmp
  echo Installing consul ${CONSULVER}
  wget https://releases.hashicorp.com/consul/${CONSULVER}/consul_${CONSULVER}_linux_amd64.zip
  unzip consul_${CONSULVER}_linux_amd64.zip
  chown root:root consul
  mv consul /usr/local/bin
  consul -autocomplete-install
  complete -C /usr/local/bin/consul consul
  
  # create consul user
  useradd --system --home /opt/consul --shell /bin/false consul
  
  # consul data directory
  [ -d /opt/consul ] || {
    mkdir --parents /opt/consul
    chown --recursive consul:consul /opt/consul
  }
  
  # copy consul configuration 
  [ -d /etc/consul.d ] || {
    mkdir --parents /etc/consul.d
    tee -a /etc/consul.d/consul.hcl <<EOF
bootstrap_expect   = 1
client_addr        = "0.0.0.0"
bind_addr          = "{{ GetInterfaceIP \"bond0\" }}"
data_dir           = "/opt/consul"
datacenter         = "${CONSUL_DC}"
log_level          = "INFO"
server             = true
ui                 = true
non_voting_server  = false
retry_join         = [
  "provider=packet auth_token=${metal_token} project=${project_id}  address_type=public_v4"
]

autopilot         = {
  cleanup_dead_servers      = true,
  last_contact_threshold    ="200ms",
  max_trailing_logs         = 250,
  server_stabilization_time = "10s",
  redundancy_zone_tag       = "zone",
  disable_upgrade_migration = false,
  upgrade_version_tag       = "",
}
node_meta = { },

connect = {
  enabled = true
}

telemetry = {
  prometheus_retention_time = "24h",
  disable_hostname = true
}
EOF

    chmod 640 /etc/consul.d/consul.hcl
    chown --recursive consul:consul /etc/consul.d
    wget -q -O /etc/systemd/system/consul.service https://raw.githubusercontent.com/Eqix-ProjectX/terraform-equinix-sd/main/srv/consul.service
    systemctl enable consul
    systemctl start consul
    systemctl status consul
  }
}