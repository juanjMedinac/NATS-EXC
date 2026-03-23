pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        // Credenciales de Proxmox e infraestructura
        PROXMOX_HOST         = credentials('PROXMOX_HOST')
        LXC_IP               = credentials('LXC_IP_NATS')

        // Terraform toma estas variables automáticamente (prefijo TF_VAR_)
        TF_VAR_proxmox_host  = credentials('PROXMOX_HOST')
        TF_VAR_lxc_ip        = credentials('LXC_IP_NATS')

        // Rutas fijas
        ANSIBLE_DIR          = "${WORKSPACE}/ansible"
        TERRAFORM_DIR        = "${WORKSPACE}/terraform"
        ANSIBLE_INVENTORY    = "${WORKSPACE}/ansible/inventory.tmp"
    }

    stages {
        // ---------------------------------------------------------------- //
        // 1. Checkout                                                        //
        // ---------------------------------------------------------------- //
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ---------------------------------------------------------------- //
        // 2. Terraform — Crear o actualizar el LXC en Proxmox               //
        // ---------------------------------------------------------------- //
        stage('Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'PROXMOX_API_TOKEN',  variable: 'TF_VAR_proxmox_token_secret'),
                ]) {
                    dir("${TERRAFORM_DIR}") {
                        sh '''
                            set -e
                            echo ">>> terraform init"
                            terraform init -input=false

                            echo ">>> terraform validate"
                            terraform validate

                            echo ">>> terraform apply"
                            terraform apply -auto-approve \
                                -var="lxc_ip=${LXC_IP}"
                        '''
                    }
                }
            }
        }

        // ---------------------------------------------------------------- //
        // 3. Ansible — Instalar Docker y desplegar NATS                     //
        // ---------------------------------------------------------------- //
        stage('Deploy') {
            steps {
                // Generar inventory dinámico con la IP correcta
                sh '''
                    sed "s/NATS_LXC_IP/${LXC_IP}/" \
                        ${ANSIBLE_DIR}/inventory > ${ANSIBLE_INVENTORY}
                '''

                // Deshabilitar host key checking en pipelines automatizados
                withEnv(['ANSIBLE_HOST_KEY_CHECKING=False']) {
                    sh '''
                        set -e
                        echo ">>> ansible-playbook deploy.yml"
                        ansible-playbook \
                            -i ${ANSIBLE_INVENTORY} \
                            ${ANSIBLE_DIR}/deploy.yml \
                            -v
                    '''
                }
            }
        }

        // ---------------------------------------------------------------- //
        // 4. Health Check — Verificar que NATS responde                     //
        // ---------------------------------------------------------------- //
        stage('Health Check') {
            steps {
                withEnv(['ANSIBLE_HOST_KEY_CHECKING=False']) {
                    sh '''
                        set -e
                        echo ">>> ansible-playbook healthcheck.yml"
                        ansible-playbook \
                            -i ${ANSIBLE_INVENTORY} \
                            ${ANSIBLE_DIR}/healthcheck.yml \
                            -v
                    '''
                }
            }
            post {
                always {
                    // Limpia el inventory temporal que contiene la IP
                    sh 'rm -f ${ANSIBLE_INVENTORY}'
                }
            }
        }
    }

    post {
        success {
            echo """
✅  Despliegue #${env.BUILD_NUMBER} completado
NATS disponible en ${LXC_IP}:4222
Monitoreo en    http://${LXC_IP}:8222

"""
        }
        failure {
            echo "❌ Falló el build #${env.BUILD_NUMBER} — revisa los logs arriba"
        }
        cleanup {
            // Limpia workspace para no acumular archivos entre builds
            cleanWs(notFailBuild: true)
        }
    }
}