# Most of the defaults below reflect settings on CC Arbutus

variable "environment_name" {
  description = "Environment name"
}

variable "domain_name" {
  description = "Domain name"
  default     = "syzygy.ca"
}

variable "block_device_source_id" {
  description = "UUID to create VM backing store from (typically a glance image ID)"
  default     = "ca4f2334-cdbd-405f-943a-258657a81d1f"
}

variable "block_device_type" {
  description = "Block device type for backing store"
  default     = "image"
}

variable "flavor_name" {
  description = "Flavor of instance (e.g. c2-7.5gb-31, provider dependent)"
  default     = "c2-7.5gb-31"
}

variable "key_name" {
  description = "Public key for ssh authentication"
  default     = "id-cc-openstack"
}

variable "security_group_name" {
  description = "Security group to assign to this host"
  default     = "syzygy"
}

variable "network_name" {
  description = "Network name to place instance on"
  default     = "rpp-colliand-network"
}

variable "existing_volumes" {
  description = "List of existing volumes to attach to instance"
  type        = "list"
  default     = []
}

variable "floatingip_pool" {
  description = "Pool to select floating IPs from"
  default     = "Public-Network"
}

variable "vol_data_size" {
  description = "Size of ZFS data volume in gigabytes"
  default     = 10
}

locals {
  cloudconfig = <<EOF
    #cloud-config
    preserve_hostname: true
    runcmd:
      - sed -i '/\/dev\/vdb/d' /etc/fstab
      - swaplabel -L swap0 /dev/sdb
      - echo "LABEL=swap0 none  swap  defaults  0  0" >> /etc/fstab
    system_info:
      default_user:
        name: ptty2u
  EOF
}
