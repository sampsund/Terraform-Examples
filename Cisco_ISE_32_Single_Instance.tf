# The below script is to provision one instance of Cisco ISE 3.2 on Azure.data

# Create new Resource Group
resource "azurerm_resource_group" "ise_resource_group" {
  name     = "cisco-ise-rg"
  location = "eastus"
}

# Create new Virtual Network 
resource "azurerm_virtual_network" "ise_virtual_network" {
  name                = "ise-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ise_resource_group.location
  resource_group_name = azurerm_resource_group.ise_resource_group.name
}

#Create new Subnet
resource "azurerm_subnet" "ise_subnet" {
  name                 = "isesubnet1"
  address_prefixes     = ["10.0.10.0/24"]
  virtual_network_name = azurerm_virtual_network.ise_virtual_network.name
  resource_group_name  = azurerm_resource_group.ise_resource_group.name

}

#Create Public IP
resource "azurerm_public_ip" "ise_pub_ip" {
  name                = "ise_public_ip"
  allocation_method   = "Dynamic"
  location            = azurerm_resource_group.ise_resource_group.location
  resource_group_name = azurerm_resource_group.ise_resource_group.name
}

# Create new Network Security Group
resource "azurerm_network_security_group" "ise_network_security_group" {
  name                = "isenetworksecuritygroup"
  location            = azurerm_resource_group.ise_resource_group.location
  resource_group_name = azurerm_resource_group.ise_resource_group.name

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
  security_rule {
    name                       = "https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#Create NIC
resource "azurerm_network_interface" "ise_nic" {
  name                = "ise_nic"
  location            = azurerm_resource_group.ise_resource_group.location
  resource_group_name = azurerm_resource_group.ise_resource_group.name

  ip_configuration {
    name                          = "ise_nic_ip"
    subnet_id                     = azurerm_subnet.ise_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ise_pub_ip.id

  }
}

# Map Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "ise_nsg_nic" {
  network_interface_id      = azurerm_network_interface.ise_nic.id
  network_security_group_id = azurerm_network_security_group.ise_network_security_group.id

}

# Create new ISE Virtual Machine
resource "azurerm_linux_virtual_machine" "ise_32_vm" {
  name                  = "ise32vm"
  location              = azurerm_resource_group.ise_resource_group.location
  resource_group_name   = azurerm_resource_group.ise_resource_group.name
  network_interface_ids = [azurerm_network_interface.ise_nic.id]
  size                  = "Standard_F16s_v2"
  admin_username        = "iseadmin"
  user_data             = base64encode(file("isecustomdata.txt"))

  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-ise-virtual"
    sku       = "cisco-ise_3_2"
    version   = "3.2.0"
  }

  plan {
    name      = "cisco-ise_3_2"
    publisher = "cisco"
    product   = "cisco-ise-virtual"
  }

  admin_ssh_key {
    username   = "iseadmin"
    public_key = file("/Users/sampathsundararajan/.ssh/id_rsa.pem.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}






