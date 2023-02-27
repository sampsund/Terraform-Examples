variable "resource_group_name" {
  description = "This is the name of the Resource Group"
  type        = string
  default     = "cl-rg"
}
variable "resource_group_location" {
  description = "This is the name of the location"
  type        = string
  default     = "eastus"
}
variable "virtual_network_name" {
  description = "This is the name of the Virtual network"
  type        = string
  default     = "cl-virtual-network"
}
variable "virtual_network_address_space" {
  description = "This address space is used by virtual network"
  default     = ["10.0.0.0/16"]
}
variable "subnet" {
  description = "This is the name of the Subnet"
  type        = string
  default     = "clsubnet"
}
variable "address_prefixes" {
  description = "This address prefix is used for virtual machines"
  default     = ["10.0.10.0/24"]
}
variable "public_ip_name" {
  description = "Public IP"
  type        = string
  default     = "Static"
}
variable "tags" {
  description = "Tags"
  default = {
    "Environment" = "Sandbox"
    "Project"     = "Project-CL"
  }
}
variable "admin_username" {
  default = "azadmin"
}

variable "admin_password" {
  default = "T3rr@123$#"
}
