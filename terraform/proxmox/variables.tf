variable "proxmox_api_url" {
  type = string
}

variable "proxmox_user" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "ci_user" {
  type = string
}

variable "ci_password" {
  type      = string
  sensitive = true
}

variable "sshkeys" {
  type = string
}
