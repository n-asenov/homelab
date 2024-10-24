resource "proxmox_virtual_environment_vm" "k8s" {
  for_each = local.virtual_machines

  name      = each.key
  node_name = "pve"

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  started       = true

  cpu {
    type    = "x86-64-v2-AES"
    sockets = 1
    cores   = each.value.cpu_cores
    units   = 100
  }

  memory {
    dedicated = each.value.memory
    floating  = each.value.memory
  }

  network_device {

  }

  disk {
    datastore_id = "fast"
    file_id      = "local:iso/nocloud-amd64.img"
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    size         = 100
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = "192.168.1.1"
      }
    }
  }
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = "homelab"
  machine_type     = "controlplane"
  cluster_endpoint = "https://192.168.1.20:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = local.controlplane_virtual_machines

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.node
  endpoint                    = each.value.endpoint
  config_patches = [
    local.talos_install_image_config_patch,
    local.talos_vip_config_patch,
    local.talos_sysctls_config_patch,
    local.talos_kubelet_config_patch,
    local.talos_cluster_network_config_patch,
    local.talos_cilium_install_config_patch
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = "homelab"
  machine_type     = "worker"
  cluster_endpoint = "https://192.168.1.20:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.worker_virtual_machines

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.node
  endpoint                    = each.value.endpoint
  config_patches = [
    local.talos_install_image_config_patch,
    local.talos_sysctls_config_patch,
    local.talos_kubelet_config_patch,
    local.talos_cluster_network_config_patch
  ]
}

resource "time_sleep" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  create_duration = "30s"
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    time_sleep.this
  ]
  node                 = "192.168.1.21"
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = "192.168.1.21"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = pathexpand("~/.kube/config")
}

data "talos_client_configuration" "this" {
  cluster_name         = "homelab"
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    "192.168.1.21",
    "192.168.1.22",
    "192.168.1.23"
  ]
  nodes = [
    "192.168.1.21",
    "192.168.1.22",
    "192.168.1.23",
    "192.168.1.24",
    "192.168.1.25",
    "192.168.1.26",
    "192.168.1.27",
    "192.168.1.28",
    "192.168.1.29"
  ]
}

resource "local_sensitive_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = pathexpand("~/.talos/config")
}
