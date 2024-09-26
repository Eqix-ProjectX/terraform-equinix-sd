variable "project_id" {
  type    = string
  default = ""
}

variable "consul_version" {
  description = "Version for the Consul"
  type        = string
  default     = ""
}

variable "metal_token" {
  description = "metal token used for consul retry-join"
  type        = string
  default     = ""
}

variable "consul_dc" {
  description = "Consul Server Datacenter name"
  type        = string
  default     = ""
}
