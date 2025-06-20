locals {
  controlplane_virtual_machines = {
    k8s-1 = {
      ipv4_address = "192.168.0.21"
      cpu_cores    = 4
      memory       = 4096
      hostpci      = []
      gpu          = []
      usb          = []
    }
    k8s-2 = {
      ipv4_address = "192.168.0.22"
      cpu_cores    = 4
      memory       = 4096
      hostpci      = []
      gpu          = []
      usb          = []
    }
    k8s-3 = {
      ipv4_address = "192.168.0.23"
      cpu_cores    = 4
      memory       = 4096
      hostpci      = []
      gpu          = []
      usb          = []
    }
  }

  worker_virtual_machines = {
    k8s-4 = {
      ipv4_address = "192.168.0.24"
      cpu_cores    = 8
      memory       = 12288
      hostpci      = ["0000:01:00"]
      gpu          = ["0000:00:02"]
      usb          = []
    }
    k8s-5 = {
      ipv4_address = "192.168.0.25"
      cpu_cores    = 8
      memory       = 12288
      hostpci      = ["0000:02:00"]
      gpu          = []
      usb          = ["10c4:ea60"]
    }
    k8s-6 = {
      ipv4_address = "192.168.0.26"
      cpu_cores    = 8
      memory       = 12288
      hostpci      = ["0000:09:00"]
      gpu          = []
      usb          = []
    }
  }
}

locals {
  # renovate: datasource=docker depName=ghcr.io/siderolabs/kubelet
  kubernetes_version = "v1.33.2"

  talos_install_image_config_patch = yamlencode({
    machine = {
      install = {
        image = data.talos_image_factory_urls.this.urls.installer
      }
    }
  })

  talos_vip_config_patch = yamlencode({
    machine = {
      network = {
        interfaces = [
          {
            interface = "eth0"
            vip = {
              ip = "192.168.0.20"
            }
          }
        ]
      }
    }
  })

  talos_sysctls_config_patch = yamlencode({
    machine = {
      sysctls = {
        "fs.inotify.max_queued_events"  = "65536"
        "fs.inotify.max_user_watches"   = "524288"
        "fs.inotify.max_user_instances" = "8192"
        "net.core.rmem_max"             = 7500000 # Cloudflared / QUIC
        "net.core.wmem_max"             = 7500000 # Cloudflared / QUIC
      }
    }
  })

  talos_kernel_modules_config_patch = yamlencode({
    machine = {
      kernel = {
        modules = [{ name = "nbd" }]
      }
    }
  })

  talos_kubelet_config_patch = yamlencode({
    machine = {
      kubelet = {
        extraArgs = {
          serialize-image-pulls = false
        }
      }
    }
  })

  talos_containerd_config_patch = yamlencode({
    machine = {
      files = [{
        path    = "/etc/cri/conf.d/20-customization.part"
        op      = "create"
        content = <<-EOT
        [plugins."io.containerd.cri.v1.images"]
          discard_unpacked_layers = false
        EOT
      }]
    }
  })

  talos_kubernetes_talos_api_access_config_patch = yamlencode({
    machine = {
      features = {
        kubernetesTalosAPIAccess = {
          enabled                     = true
          allowedRoles                = ["os:admin"]
          allowedKubernetesNamespaces = ["system-upgrade"]
        }
      }
    }
  })

  talos_cluster_network_config_patch = yamlencode({
    cluster = {
      network = {
        cni = {
          name = "none"
        }
      }
      proxy = {
        disabled = true
      }
    }
  })

  talos_cluster_controller_manager_config_patch = yamlencode({
    cluster = {
      controllerManager = {
        extraArgs = {
          bind-address = "0.0.0.0"
        }
      }
    }
  })

  talos_cluster_scheduler_config_patch = yamlencode({
    cluster = {
      scheduler = {
        extraArgs = {
          bind-address = "0.0.0.0"
        }
      }
    }
  })

  talos_cluster_etcd_config_patch = yamlencode({
    cluster = {
      etcd = {
        extraArgs = {
          listen-metrics-urls = "http://0.0.0.0:2381"
        }
      }
    }
  })

  talos_cluster_apiserver_config_patch = yamlencode({
    cluster = {
      apiServer = {
        disablePodSecurityPolicy = true
        admissionControl = [
          {
            name     = "PodSecurity"
            "$patch" = "delete"
          }
        ]
        resources = {
          requests = {
            cpu    = "200m"
            memory = "512Mi"
          }
          limits = {
            memory = "1Gi"
          }
        }
      }
    }
  })

  talos_cluster_coredns_config_patch = yamlencode({
    cluster = {
      coreDNS = {
        disabled = true
      }
    }
  })

  talos_user_volume_config_patch = yamlencode({
    apiVersion = "v1alpha1"
    kind       = "UserVolumeConfig"
    name       = "openebs"
    provisioning = {
      diskSelector = {
        match = "disk.transport == 'virtio' && !system_disk"
      }
      minSize = "64GB"
      grow    = true
    }
  })
}
