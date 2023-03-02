# Create the resource group
# Resource group name, Resource group location and tags are declated as variables in variables.tf file
resource "azurerm_resource_group" "cl_resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

#Create the virtual network
resource "azurerm_virtual_network" "cl_virtual_network" {
  name                = "cl_virtual_network"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.cl_resource_group.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

#Create the subnet
resource "azurerm_subnet" "cl_subnet" {
  name                 = "cl_subnet"
  resource_group_name  = azurerm_resource_group.cl_resource_group.name
  virtual_network_name = azurerm_virtual_network.cl_virtual_network.name
  address_prefixes     = ["10.0.10.0/24"]
}

#Create Public IP for Linux VM Host
resource "azurerm_public_ip" "cl_linuxvm_pub_ip" {
  name                = var.public_ip_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.cl_resource_group.name
  allocation_method   = "Static"
  tags                = var.tags
}

# Create new Network Security Group
resource "azurerm_network_security_group" "linux_network_security_group" {
  name                = "linux_network_security_group"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.cl_resource_group.name


  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#Create NIC
resource "azurerm_network_interface" "cl_linuxvm_nic" {
  name                = "cl_linuxvm_nic"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.cl_resource_group.name

  ip_configuration {
    name                          = "cl_linuxvm_nic"
    subnet_id                     = azurerm_subnet.cl_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.10.4"
    public_ip_address_id          = azurerm_public_ip.cl_linuxvm_pub_ip.id
  }
}

# Map Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "ise_nsg_nic" {
  network_interface_id      = azurerm_network_interface.cl_linuxvm_nic.id
  network_security_group_id = azurerm_network_security_group.linux_network_security_group.id
}

# Create Private DNS Zone - Forward
resource "azurerm_private_dns_zone" "cldns" {
  name                = "cl.test"
  resource_group_name = azurerm_resource_group.cl_resource_group.name
  tags                = var.tags

}

# Create A record in Private DNS Zone - Forward
resource "azurerm_private_dns_a_record" "cldns_linux_a_record" {
  name                = "cl-linuxvm"
  zone_name           = azurerm_private_dns_zone.cldns.name
  resource_group_name = azurerm_resource_group.cl_resource_group.name
  ttl                 = 300
  records             = [azurerm_network_interface.cl_linuxvm_nic.private_ip_address]
  tags                = var.tags

}

# Linking Virtual Network and Private DNS Zone - Forward
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_virtual_network_link" {
  name                  = "private_dns_virtual_network_link"
  resource_group_name   = azurerm_resource_group.cl_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.cldns.name
  virtual_network_id    = azurerm_virtual_network.cl_virtual_network.id
  registration_enabled  = true
}

# Create Private DNS Zone - Reverse
resource "azurerm_private_dns_zone" "private_reverse_dns" {
  name                = "10.0.10.in-addr.arpa"
  resource_group_name = azurerm_resource_group.cl_resource_group.name
  tags                = var.tags
}

# Create A record in Private DNS Zone - Reverse
resource "azurerm_private_dns_ptr_record" "private_dns_ptr_record_4" {
  name                = "4"
  zone_name           = azurerm_private_dns_zone.private_reverse_dns.name
  resource_group_name = azurerm_resource_group.cl_resource_group.name
  ttl                 = 300
  records             = ["cl-linuxvm.cl.test"]
  tags                = var.tags
}

# Linking Virtual Network and Private DNS Zone - Reverse
resource "azurerm_private_dns_zone_virtual_network_link" "private_reverse_dns_virtual_network_link" {
  name                  = "private_reverse_dns_virtual_network_link"
  resource_group_name   = azurerm_resource_group.cl_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.private_reverse_dns.name
  virtual_network_id    = azurerm_virtual_network.cl_virtual_network.id
}

# Create new ISE Virtual Machine
resource "azurerm_linux_virtual_machine" "linuxvm" {
  name                            = "cl-linuxvm"
  location                        = var.resource_group_location
  resource_group_name             = azurerm_resource_group.cl_resource_group.name
  network_interface_ids           = [azurerm_network_interface.cl_linuxvm_nic.id]
  size                            = "Standard_B1s"
  computer_name                   = "cl-linuxvm"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags
  user_data = base64encode(<<-EOT
        #!/bin/bash
        sudo apt install net-tools   
        sudo apt install unzip
        wget https://releases.hashicorp.com/terraform/1.3.7/terraform_1.3.7_linux_amd64.zip
        unzip terraform_1.3.7_linux_amd64.zip
        sudo mv terraform /home/azadmin
        sudo apt update -y
        sudo apt install python3-pip -y
        sudo apt install python-is-python3 -y
        sudo apt install ansible -y
        sudo pip3 install ciscoisesdk
        sudo ansible-galaxy collection install cisco.ise -p /usr/lib/python3/dist-packages/
        sudo curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        sudo apt install azure-cli
        sudo bash -c "echo '127.0.0.1 cl-linuxvm' >> /etc/hosts"
        sudo bash -c "echo 'nameserver 168.63.129.16' >> /etc/resolv.conf" 
  EOT
  )

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy-daily"
    sku       = "22_04-daily-lts"
    version   = "latest"
  }
  os_disk {
    name                 = "linuxvmdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

  }
# This parameter is used to enable SSH access to the Linux VM for Admin purposes.
  admin_ssh_key {
    username   = "azadmin"
    public_key = file("~/.ssh/cl_rsa.pub")
  }

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.cl_linuxvm_pub_ip.ip_address
    user     = var.admin_username
    password = var.admin_password
    agent = false
  }

  provisioner "file" {
    source      = "/Users/isemulti/CiscoISE3.2-2nodes.tf"
    destination = "/home/azadmin/CiscoISE3.2-2nodes.tf"
  }

  provisioner "file" {
    source      = "/Users/.ssh/cl_rsa.pub"
    destination = "/home/azadmin/cl_rsa.pub"
  }

  provisioner "file" {
    source      = "/Users/.ssh/cl_rsa"
    destination = "/home/azadmin/cl_rsa"
  }
# This copies the hosts file which contains the ISE node details for executing Ansible playbook
  provisioner "file" {
    source      = "/Users/hosts"
    destination = "/home/azadmin/hosts"
  }
# This copies the inventory file which contains the ISE node details for executing Ansible playbook
  provisioner "file" {
    source      = "/Users/inventory.yaml"
    destination = "/home/azadmin/inventory.yaml"
  }
  # This copies the main Ansible playbook for the following tasks
  # Task1: Make standalone ISE node to Primary 
  # Task2: Register secondary ISE node to Primary
  provisioner "file" {
    source      = "/Users/ise.yaml"
    destination = "/home/azadmin/ise.yaml"
  }
}
