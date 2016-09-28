resource openstack_compute_secgroup_v2 k8s_secgroup {
  name        = "k8s_secgroup"
  description = "Allows ssh access to the cluster with the correct keypair"
}

resource openstack_networking_secgroup_rule_v2 secgroup_rule_ssh {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource openstack_networking_secgroup_rule_v2 secgroup_rule_https {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource openstack_networking_floatingip_v2 master_floatip {
  pool      = "public"
  tenant_id = "${var.os_project_id}"
}

resource openstack_networking_floatingip_v2 node_floatips {
  count     = "${var.config["nodes_count"]}"
  pool      = "public"
  tenant_id = "${var.os_project_id}"
}

# Create a k8s master
resource openstack_compute_instance_v2 k8s-master {
  name            = "k8s-master"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.image["flavor"]}"
  key_pair        = "${var.keypair_name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.k8s_secgroup.name}"]

  network {
    name        = "${openstack_networking_network_v2.k8s_private_net.name}"
    fixed_ip_v4 = "${var.internal_master_ip}"
  }

  floating_ip = "${openstack_networking_floatingip_v2.master_floatip.address}"

  # copies the cluster addons to master.
  provisioner file {
    connection {
      user        = "${var.ssh_user}"
      private_key = "${file(var.ssh_key_file)}"
    }

    source      = "addons"
    destination = "/home/ubuntu"
  }

  # Provision the instance
  provisioner remote-exec {
    connection {
      user        = "${var.ssh_user}"
      private_key = "${file(var.ssh_key_file)}"
    }

    script = "provision.sh"
  }

  # Bootstrap with kubeadm
  provisioner remote-exec {
    connection {
      user        = "${var.ssh_user}"
      private_key = "${file(var.ssh_key_file)}"
    }

    inline = [
      "sudo kubeadm init --pod-network-cidr ${var.pod_overlay_cidr} --token ${var.bootstrap_token}",
      "kubectl create -f /home/ubuntu/addons/flannel-cfg.yaml",
      "kubectl create -f /home/ubuntu/addons/flannel-ds.yaml",
      "kubectl create -f /home/ubuntu/addons/dashboard-service.yaml",
      "kubectl create -f /home/ubuntu/addons/dashboard-controller.yaml",
    ]
  }
}

output "command" {
  value = "sudo kubeadm join --token ${var.bootstrap_token}"
}

output "master_ip" {
  value = "${openstack_compute_instance_v2.k8s-master.access_ip_v4}"
}

# Create the k8s nodes
resource openstack_compute_instance_v2 k8s-minion {
  depends_on      = ["openstack_compute_instance_v2.k8s-master"]
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

  # Provision the instance
  provisioner remote-exec {
    connection {
      user        = "${var.ssh_user}"
      private_key = "${file(var.ssh_key_file)}"
    }

    script = "provision.sh"
  }

  # Bootstrap with kubeadm
  provisioner remote-exec {
    connection {
      user        = "${var.ssh_user}"
      private_key = "${file(var.ssh_key_file)}"
    }

    inline = [
      "sudo kubeadm join --token ${var.bootstrap_token} ${var.internal_master_ip}",
    ]
  }
}
