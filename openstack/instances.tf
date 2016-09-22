resource "openstack_compute_secgroup_v2" "k8s_secgroup" {
  name        = "k8s_secgroup"
  description = "Allows ssh access to the cluster with the correct keypair"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_floatingip_v2" "master_floatip" {
  pool      = "public"
  tenant_id = "${var.os_project_id}"
}

resource "openstack_networking_floatingip_v2" "node_floatips" {
  count     = "${var.config["nodes_count"]}"
  pool      = "public"
  tenant_id = "${var.os_project_id}"
}

# Create a k8s master
resource "openstack_compute_instance_v2" "k8s-master" {
  name            = "k8s-master"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.image["flavor"]}"
  key_pair        = "${var.keypair_name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.k8s_secgroup.name}"]

  network {
    name = "${openstack_networking_network_v2.k8s_private_net.name}"
  }

  floating_ip = "${openstack_networking_floatingip_v2.master_floatip.address}"

  # Provision the instance and run kubeadm
  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_file)}"
    }

    script = "provision_master.sh"
  }
}

# Create the k8s nodes
resource "openstack_compute_instance_v2" "k8s-minion" {
  count           = "${var.config["nodes_count"]}"
  name            = "k8s-node-${count.index}"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.image["flavor"]}"
  key_pair        = "${var.keypair_name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.k8s_secgroup.name}"]

  network {
    name = "${openstack_networking_network_v2.k8s_private_net.name}"
  }

  floating_ip = "${element(openstack_networking_floatingip_v2.node_floatips.*.address, count.index)}"

  # Provision the instance and run kubeadm
  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_file)}"
    }

    script = "provision_node.sh"
  }
}
