variable "resource_group_name" {
  default = "rg-vm-casopractico2"
}

variable "location_name" {
  type        = string
  description = "Región de Azure donde crearemos la infraestructura"
  default = "eastus2"
}

variable "network_name" {
  description = "virtual network donde se creara la VM"
  default = "vnet1-casopractico2"
}

variable "subnet_name" {
  description = "subnet donde se creara la maquina virtual"
  default = "st-casopractico2"
}
