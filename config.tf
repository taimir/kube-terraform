variable os_user_name {
  type = "string"
}

variable os_user_password {
  type = "string"
}

variable os_project_name {
  type    = "string"
  default = "k8s-terraform"
}

variable os_project_id {
  type    = "string"
  default = "e23c0b230228475aafc01d560db6cd40"
}

variable os_auth_url {
  type    = "string"
  default = "http://172.31.0.81:5000/v2.0"
}

variable keypair_name {
  type    = "string"
  default = "k8s_keypair"
}

variable image {
  type = "map"

  default = {
    name   = "Ubuntu Xenial"
    flavor = "m1.medium"
  }
}

variable node_root_password {
  type    = "string"
  default = "root123"
}

variable "config" {
  type = "map"

  default = {
    # networking
    external_network_id  = "b8316571-4b9c-4f5f-8726-7ef453ba683a"
    private_network_name = "k8s_private"

    # machines information
    nodes_count         = "1"
    master_flavor       = "m1.medium"
    minion_flavor       = "m1.medium"
    image_download_from = "https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.vmdk"
    image_type          = "vmdk"

    # k8s installation
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.os_user_name}"
  tenant_name = "${var.os_project_name}"
  password    = "${var.os_user_password}"
  auth_url    = "${var.os_auth_url}"
}
