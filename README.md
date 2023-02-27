Work in Progress...

## Provision of Ubuntu Linux VM on Azure
#### The terraform file cl-linuxvm.tf provisions Ubuntu Linux vm. The following are created as part of the Ubuntu provisioning process.
  * Create a Resource Group "cl_resource_group"
  * Create a Virtual Network "cl_virtual_network"
  * Create a Subnet "cl_subnet"
  * Create and assign Public IP "cl_linuxvm_pub_ip"
  * Create a Network Security Group to allow only "SSH access"
  * Create an interface "cl_linuxvm_nic"
  * Associate Network Security Group to Interface
  * Create a Private DNS Zone(Forward DNS)
  * Create a "A" record in that Private DNS Zone
  * Create a Virtual Network link with that Private DNS Zone
  * Create a Private DNS Zone(Reverse DNS)
  * Create a "PTR" record in that Private DNS Zone
  * Create a Virtual Network link with that Private DNS Zone
  * Create Ubuntu Virtual Machine
----------
## Provision of Cisco ISE - 2 Nodes on Azure
#### The Terraform file "CiscoISE32-2nodes.tf" provisions Cisco Identity Services Engine (ISE) 3.2. The following are performed as part of the ISE provisioning process.

----------
- Execute Ansible script to Make the node as Primary and register the secondary node


----------
