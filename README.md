# Terraform deployment

Deployment can be controlled (number of VMs of each tier) via variables in `terraform.tfvars`.

What would be deployed:
  - One virtual network with three subnets
  - DB Subnet with NSG blocking outbound connectivity to the Internet
  - Bastion as a jump host
  - DB VMs are MSSQL enabled (SQL Server 2017 with PAYG Enterprise license)
  - WEB VMs are with IIS installed
  - Windows Server version 2016 (Full Desktop)
  - Size of VMs are set to Standard_B2ms (can be changed in `terraform.tfvars`)
