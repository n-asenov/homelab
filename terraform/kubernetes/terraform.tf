terraform {
  cloud {
    organization = "nasenov"

    workspaces {
      name = "kubernetes"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.2"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
  }
}
