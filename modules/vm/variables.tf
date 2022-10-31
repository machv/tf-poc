variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "name" {
  type = string
}

variable "os_name" {
  type = string
}

variable "enable_ping" {
    type = bool
    default = false
}

variable "size" {
  type = string
  default = "Standard_B2ms"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "data_disks" {
  type = list(object({
    size_gb = number
    name = string
    tier = string
    lun = number
  }))
  default = []
}

variable "use_mssql" {
  type = bool
  default = false
}

variable "mssql_data_settings" {
    type = object({
        luns = list(number)
        file_path = string
    })
    default = null
}

variable "mssql_temp_db_settings" {
    type = object({
        luns = list(number)
        file_path = string
    })
    default = null
}

variable "mssql_log_settings" {
    type = object({
        luns = list(number)
        file_path = string
    })
    default = null
}
