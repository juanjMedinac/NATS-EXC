# NATS on Proxmox LXC — Infrastructure as Code

Despliega un servidor **NATS** (con JetStream habilitado) dentro de un
contenedor LXC en Proxmox, usando Docker Compose, Terraform, Ansible y Jenkins.

## Estructura

```
nats-infra/
├── Jenkinsfile                   # Pipeline principal
├── terraform/
│   ├── main.tf                   # LXC en Proxmox
│   ├── variables.tf
│   └── terraform.tfvars.example  # Copia y ajusta
└── ansible/
    ├── deploy.yml                # Instala Docker + levanta NATS
    ├── healthcheck.yml           # Verifica que NATS responde
    ├── inventory                 # Plantilla de inventario
    └── files/
        ├── compose.yml    # Definición del servicio NATS
        └── nats-server.conf      # Configuración de NATS
```

## Credenciales requeridas en Jenkins

| ID en Jenkins       | Descripción                          |
| ------------------- | ------------------------------------ |
| `PROXMOX_HOST`      | IP o FQDN del nodo Proxmox           |
| `PROXMOX_API_TOKEN` | Secret del token de Proxmox          |
| `LXC_IP_NATS`       | IP estática que tendrá el contenedor |
| `LXC_GATEWAY`       | Gateway de la red del contenedor     |

## Puertos expuestos

| Puerto | Uso                              |
| ------ | -------------------------------- |
| 4222   | Clientes NATS                    |
| 8222   | Monitoreo HTTP (`/healthz` etc.) |
| 6222   | Clustering entre nodos           |

## Endpoints de monitoreo útiles

```
http://<IP>:8222/healthz   → estado del servidor
http://<IP>:8222/varz      → variables del servidor
http://<IP>:8222/connz     → conexiones activas
http://<IP>:8222/jsz       → estado de JetStream
```

## Ejecución manual (sin Jenkins)

```bash
# 1. Infraestructura
cd terraform
cp terraform.tfvars.example terraform.tfvars  # edita los valores
terraform init && terraform apply

# 2. Despliegue
cd ../ansible
# Edita inventory con la IP correcta
ansible-playbook -i inventory deploy.yml

# 3. Health check
ansible-playbook -i inventory healthcheck.yml
```

## Requerimientos en el nodo Jenkins

- Terraform ≥ 1.6
- Ansible ≥ 2.14 + colección `community.docker`
  ```bash
  ansible-galaxy collection install community.docker
  ```
- Acceso SSH al LXC (llave en `/var/lib/jenkins/.ssh/`)
