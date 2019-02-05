terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

resource "openstack_networking_floatingip_v2" "fip" {
  pool = "${var.floatingip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  instance_id = "${openstack_compute_instance_v2.hub.id}"
  floating_ip = "${openstack_networking_floatingip_v2.fip.address}"
}

resource "openstack_compute_instance_v2" "hub" {
  name            = "${var.environment_name}"
  flavor_name     = "${var.flavor_name}"
  key_pair        = "${var.key_name}"
  security_groups = ["${var.security_group_name}"]
  user_data       = "${local.cloudconfig}"

  # Keep the root disk on a volume
  block_device {
    uuid             = "${var.block_device_source_id}"
    source_type      = "${var.block_device_type}"
    volume_size      = 30
    boot_index       = 0
    destination_type = "volume"

    # This is messy but necessary because of how we resize
    delete_on_termination = false
  }

  network {
    name = "${var.network_name}"
  }
}

# Determine the volume UUIDs, whether if existing ones were supplied
# or if new ones were created.
locals {
  vol_id_1 = "${length(var.existing_volumes) == 0 ?
    element(concat(openstack_blockstorage_volume_v2.data.*.id, list("")), 0) :
    element(concat(var.existing_volumes, list("")), 0)
  }"
}

resource "openstack_blockstorage_volume_v2" "data" {
  count = "${length(var.existing_volumes) == 0 ? 1 : 0}"
  name  = "${format("%s-data-%02d", var.environment_name, count.index+1)}"
  size  = "${var.vol_data_size}"
}

resource "openstack_compute_volume_attach_v2" "data_1" {
  instance_id = "${openstack_compute_instance_v2.hub.id}"
  volume_id   = "${local.vol_id_1}"
}

resource "ansible_group" "stats" {
  inventory_group_name = "stats"
}

resource "ansible_host" "stats" {
  inventory_hostname = "${var.environment_name}.${var.domain_name}"
  groups             = ["stats"]

  vars {
    ansible_user = "ptty2u"

    ansible_host            = "${openstack_networking_floatingip_v2.fip.address}"
    ansible_ssh_common_args = "-C -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    syzygy_data_id       = "/dev/disk/by-id/virtio-${substr(openstack_compute_volume_attach_v2.data_1.volume_id, 0, 20)}"
  }
}
