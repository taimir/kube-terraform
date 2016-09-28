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
  security_groups = ["default", "${openstack_networking_secgroup_v2.k8s_secgroup.name}"]

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
      "kubectl create -f /home/ubuntu/addons/kube-flannel.yaml",
      "kubectl create -f /home/ubuntu/addons/dashboard-service.yaml",
      "kubectl create -f /home/ubuntu/addons/dashboard-controller.yaml",
    ]
  }

  # Configure local kubectl
  provisioner local-exec {
    command = "./configure-kubectl.sh ${var.bootstrap_token} ${openstack_compute_instance_v2.k8s-master.access_ip_v4}"
  }
}

output SUCCESS {
  value = "Run `kubectl proxy` on your local machine and access dashboard under http://localhost:8001/ui :)"
}

# Create the k8s nodes
resource openstack_compute_instance_v2 k8s-minion {
  depends_on      = ["openstack_compute_instance_v2.k8s-master"]
  count           = "${var.config["nodes_count"]}"
  name            = "k8s-node-${count.index}"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.image["flavor"]}"
  key_pair        = "${var.keypair_name}"
  security_groups = ["default", "${openstack_networking_secgroup_v2.k8s_secgroup.name}"]

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
