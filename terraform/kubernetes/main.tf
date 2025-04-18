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
    cache        = "writeback"
  }

  dynamic "hostpci" {
    for_each = each.value.hostpci

    content {
      device = "hostpci0"
      id     = hostpci.value
      pcie   = true
      rombar = true
    }
  }

  dynamic "hostpci" {
    for_each = each.value.gpu

    content {
      device = "hostpci0"
      id     = hostpci.value
      pcie   = true
      rombar = false
    }
  }

  dynamic "usb" {
    for_each = each.value.usb

    content {
      host = usb.value
    }
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-lvm"

    dns {
      servers = ["192.168.0.53"]
    }

    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = "192.168.0.1"
      }
    }
  }
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = "v1.9.5"
  filters = {
    names = [
      "qemu-guest-agent",
      "i915"
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
      }
    }
    }
  )
}

data "talos_image_factory_urls" "this" {
  talos_version = "v1.9.5"
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = "homelab"
  machine_type     = "controlplane"
  cluster_endpoint = "https://192.168.0.20:6443"
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
    local.talos_containerd_config_patch,
    local.talos_cluster_network_config_patch,
    local.talos_discovery_service_patch,
    local.talos_cluster_controller_manager_config_patch,
    local.talos_cluster_scheduler_config_patch,
    local.talos_cluster_etcd_config_patch,
    local.talos_cluster_apiserver_config_patch,
    local.talos_kubernetes_talos_api_access_config_patch
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = "homelab"
  machine_type     = "worker"
  cluster_endpoint = "https://192.168.0.20:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_bootstrap.this
  ]

  for_each = local.worker_virtual_machines

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.node
  endpoint                    = each.value.endpoint
  config_patches = [
    local.talos_install_image_config_patch,
    local.talos_sysctls_config_patch,
    local.talos_kubelet_config_patch,
    local.talos_containerd_config_patch,
    local.talos_cluster_network_config_patch,
    local.talos_discovery_service_patch
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]
  node                 = "192.168.0.21"
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = "192.168.0.21"
}

data "talos_client_configuration" "this" {
  cluster_name         = "homelab"
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    "192.168.0.21",
    "192.168.0.22",
    "192.168.0.23"
  ]
  nodes = [
    "192.168.0.21",
    "192.168.0.22",
    "192.168.0.23",
    "192.168.0.24",
    "192.168.0.25",
    "192.168.0.26",
    "192.168.0.27",
    "192.168.0.28",
    "192.168.0.29",
    "192.168.0.30"
  ]
}
