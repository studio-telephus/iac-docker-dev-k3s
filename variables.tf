variable "env" {
  type    = string
  default = "dev"
}

variable "kube_config_path" {
  type    = string
  default = ".terraform/kube_config.yml"
}

variable "autostart" {
  type    = bool
  default = true
}

