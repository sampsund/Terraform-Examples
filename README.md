- The terraform file "cl-linuxvm.tf" provisions Ubuntu Linux vm on Azure cloud. The following are achieved as part of the Ubuntu provisioning process.
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
  
- Next use the already provisioned Ubuntu Linux to provision two ISE nodes using Terraform installed on that linux vm
- Execute Ansible script to Make the node as Primary and register the secondary node
