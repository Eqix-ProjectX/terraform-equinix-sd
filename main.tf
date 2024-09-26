resource "random_pet" "this" {
  length = 2
}

module "key" {
  source     = "git::github.com/andrewpopa/terraform-metal-project-ssh-key"
  project_id = var.project_id
}

data "template_file" "consul_server" {
  template = file("boot/consul.sh")
  vars = {
    CONSULVER   = var.consul_version
    metal_token = var.metal_token
    project_id  = var.project_id
    CONSUL_DC   = var.consul_dc
  }
}

resource "equinix_metal_device" "server" {
  hostname            = "${random_pet.this.id}-server"
  plan                = "m3.small.x86"
  metro               = "am"
  operating_system    = "ubuntu_24_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = [module.key.id]
  user_data           = data.template_file.consul_server.rendered
}

data "template_file" "consul_client" {
  template = file("boot/client.sh")
  vars = {
    CONSULVER = var.consul_version
    LEADER    = equinix_metal_device.server.access_public_ipv4
    CONSUL_DC = var.consul_dc
  }
}

resource "equinix_metal_device" "prometheus" {
  hostname            = "${random_pet.this.id}-prometheus"
  plan                = "m3.small.x86"
  metro               = "am"
  operating_system    = "ubuntu_24_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = [module.key.id]
  user_data           = data.template_file.consul_client.rendered
}
