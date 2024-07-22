# Descripción del proceso de despliegue
Estas herramientas se deben instalar en el sistema operativo donde se realizara el desplisgue, en este caso se uso Ubuntu Server 24.04
El proceso de despliegue se realiza sobre una maquina virtual en el equipo local

    
**Se uso una imagen de Ubuntu Virtual Box para realizar la ejecucion de comandos y la generacion de la imagen y deploy de recursos en Azure**
https://sourceforge.net/projects/osboxes/files/v/vb/55-U-u/24.04/64bit.7z/download

# Requisitos

1. Se deben instalar las siguientes herramientas en el sistema operativo Linux:

* Terraform
* Ansible
* Podman
* AZ cli

# Recursos generados en azure luego de realizar los pasos corresponientes en el procedimiento de ejecucion

    * Una VM en Azure del tipo Standard B1s (1 vcpu, 1 GiB memory)
        vnet con 1 subnet
        IP Publica asociada al DNS "casopractico2-dns.eastus2.cloudapp.azure.com"
        1 HDD para alojar el sistema operativo de 30GB

    * Un contenedor de registro ACR del tipo basico donde se alojaran las imagenes de las App

    * Un Cluster AKS en su version 1.29 con un solo nodo del tipo Standard_D2_v2


# Procedimiento

**Ejecutar los comandos dentro de la maquina virtual linux**
**el acceso a la misma puede ser a traves del mismo virtualizador VirtualBox o desde SSH (usuario: osboxes, pass:osboxes.org)**

1. Ejecucion de comandos para los requisitos

# Instalar terraform:
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Instalar Ansible en Linux
sudo apt install ansible -y
ssh-keygen -t rsa                           **generar clave publica-privada (se usara para acceso SSH a VM y ansible la usara)**
                                            **se guarda automaticamente en ~/.ssh/id_rsa**

# Instalar Podman en ubuntu:
sudo apt install -y podman

# Instalar AZ cli, Cliente Azure:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash


2.  Realizar login en Azure para poder generar recursos con terraform:

# Login en Azure y creacion de recursos en azure:
az login        //introducir credenciales de Azure

# Creacion ACR con terraform (01_terraform_acr)
terraform init -upgrade                                                         **Inicializar Terraform, en dir donde se encuentra los archivos a desplegar recursos descarga los modulos necesarios**
terraform plan -out acr.tfplan                                                  **genera plan de ejecucion**
terraform apply acr.tfplan                                                      **ejecuta plan de ejecucion**
az acr credential show -n acrcasopractico2 --query 'passwords[0].value' -o tsv  **guardar el password de acceso para su posterior uso en el despligue del contenedor en azure**


3.  Creacion de VM en Azure y posterior subida de imagen

# Loguearse en ACR usando podman y token
acr_registry=acrcasopractico2       //defino variable y uso nombre de registro ACR
host=acrcasopractico2.azurecr.io
passwordacr=$(az acr credential show -n acrcasopractico2 --query 'passwords[0].value' -o tsv)
podman login $host -u $acr_registry -p $passwordacr     **login con Podman en ACR**

# Generar imagen aplicacion php linux a ACR, se utiliza una imagen de php-nginx con una app demo
cd 04_nginx_php_fpm                             **accedo al directorio donde se encuentra el Dockerfile**
podman build -t php-nginx-casopractico2 .       **hago el build del contenedor**

# Subir imagen de server linux a ACR
podman tag php-nginx-casopractico2 acrcasopractico2.azurecr.io/vm-podman-app:casopractico2
podman push acrcasopractico2.azurecr.io/vm-podman-app:casopractico2     **subo imagen al registro de azure**

# Creacion de VM con terraform (dentro de directorio 02_terraform_vm_ubuntu):
terraform init -upgrade           **Inicializar Terraform, en dir donde se encuentra los archivos a desplegar recursos (descarga los modulos necesarios):**
terraform plan -out vm.tfplan     **genera plan de ejecucion**
terraform apply vm.tfplan         **ejecuta plan de ejecucion**


4.  Ejecucion de Playbook Ansible para configurar imagen de VM con podman  

# Modificar archivo de variables antes de correr el playbook, se sustituye con el password de login de ACR azure ($passwordacr)
cd 03_ansible_podman
nano vars.yaml                    **modifico archivo de variables e inserto $passwordacr**

# Ejecuto playbook (03_ansible_podman)
ansible-playbook -i hosts podman-playbook.yml

# la aplicacion quedara disponible en http://casopractico2-dns.eastus2.cloudapp.azure.com:8080
**es una aplicacion php de ejemplo de reail descargada aqui: https://github.com/optimizely/php-sdk-demo-app/tree/master**


5.  # Creacion de AKS con terraform (01_terraform_acr)

az ad sp create-for-rbac --skip-assignment  **ejecuto comando para crear un service principal de Active Directory necesario para el depliegue**

**Con la salida del comando sustituyo los valores de "appId" y "password" en el archivo "terraform.tfvars"**

terraform init -upgrade           **Inicializar Terraform, en dir donde se encuentra los archivos a desplegar recursos (descarga los modulos necesarios):**
terraform plan -out aks.tfplan     **genera plan de ejecucion**
terraform apply aks.tfplan         **ejecuta plan de ejecucion**
