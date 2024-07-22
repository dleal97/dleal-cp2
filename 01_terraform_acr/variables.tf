##### General #####
variable "LOCATION" {
  description = "Datacenter de Azure donde se generaran los recursos"
  type    = string
  default = "eastus2"
}

variable "ACRNAME" {
  type        = string
  description = "Nombre del registry de imágenes de contenedor"
  default = "casopractico2"
}
