terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://${var.proxmox_host}:8006"
  api_token = "terraform@pve!terraform-token=${var.proxmox_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_container" "nats_container" {
  node_name    = "proxmox"
  unprivileged = true

  features {
    nesting = true # Requerido para correr Docker dentro del LXC
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = "${var.lxc_ip}/24"
        gateway = var.lxc_gateway
      }
    }

    user_account {
      keys = [trimspace(file(var.jenkins_public_key_path))]
    }
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = true
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.template_type
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_dedicated
  }

  started = true

  connection {
    type        = "ssh"
    user        = "root"
    host        = var.lxc_ip
    private_key = file(var.jenkins_private_key_path)
    timeout     = "3m"
  }

  # Solo bootstrapping mínimo — Ansible se encarga del resto
  provisioner "remote-exec" {
    inline = [
      "apt-get update -qq",
      "apt-get install -y -qq python3",
      "echo 'Bootstrap OK'"
    ]
  }
}