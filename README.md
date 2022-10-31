# Terraform deployment

Deployment can be configured (e.g. number of VMs of each tier) via `terraform.tfvars` file.

What would be deployed:
  - One virtual network with three subnets
    - `db` for MSSQL servers
    - `web` for IIS servers
    - `pc` for process controller servers
  - DB Subnet with NSG blocking outbound connectivity to the Internet
  - Bastion as a jump host
  - DB VMs are MSSQL enabled (SQL Server 2017 with PAYG Enterprise license)
  - WEB VMs are with IIS installed
  - Windows Server version 2016 (Full Desktop)
  - Size of VMs are set to Standard_B2ms (can be changed in `terraform.tfvars`)

Disk parameters for MSSQL servers are in `vms.tf` file in variable `data_disks` of module resource `vm_db`.
