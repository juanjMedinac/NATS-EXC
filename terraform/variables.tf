variable "proxmox_host" {}
variable "proxmox_token_secret" {}
variable "registry_host" {}
variable "registry_user" {}
variable "registry_password" {
  sensitive = true
}
variable "lxc_ip" { default = "190.1.0.108" }
variable "lxc_gateway" { default = "190.1.0.1"}
variable "template_file_id" { default = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst" }
variable "template_type" { default = "debian" }
variable "disk_size" { default = 10 }
variable "cpu_cores" { default = 2 }
variable "memory_dedicated" { default = 1024 }
variable "jenkins_public_key_path" {
  default = "/var/lib/jenkins/.ssh/id_rsa.pub"
}
variable "jenkins_private_key_path" {
  default   = "/var/lib/jenkins/.ssh/id_rsa"
  sensitive = true
}
variable "hostname" {
  default = "NATS-EXC"
}