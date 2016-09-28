# Keypair for remote access
resource openstack_compute_keypair_v2 k8s_keypair {
  name       = "k8s_keypair"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

# Private network
resource openstack_networking_network_v2 k8s_private_net {
  name           = "${var.config["private_network_name"]}"
  tenant_id      = "${var.os_project_id}"
  admin_state_up = "true"
}

resource openstack_networking_subnet_v2 k8s_private_subnet {
  name            = "${var.config["private_network_name"]}_subnet"
  network_id      = "${openstack_networking_network_v2.k8s_private_net.id}"
  cidr            = "10.33.0.0/24"
  ip_version      = 4
  dns_nameservers = "${var.cluster_DNS_servers}"
}

# Router between private and external network
resource openstack_networking_router_v2 k8s-router {
  name             = "k8s-router"
  admin_state_up   = "true"
  external_gateway = "${var.config["external_network_id"]}"
  tenant_id        = "${var.os_project_id}"
}

resource openstack_networking_router_interface_v2 router_interface_1 {
  router_id = "${openstack_networking_router_v2.k8s-router.id}"
  subnet_id = "${openstack_networking_subnet_v2.k8s_private_subnet.id}"
}

resource openstack_networking_secgroup_v2 k8s_secgroup {
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
