output "lxc_ip" {
  value = var.lxc_ip
}

output "hostname" {
  value = var.hostname
}

output "container_id" {
  value = proxmox_virtual_environment_container.app_container.id
}
