#!/bin/bash

# Install prerequisites
# 	* docker
#	* socat
#	* kubelet (systemd service)
#	* kubectl (/usr/bin binary)
# 	* kubeadm (/usr/bin binary)
echo "Starting provisioning with kubeadm"
curl -sSL https://get.docker.com/ | sh
sudo apt-get install -y socat
curl -s -L "https://www.dropbox.com/s/shhs46bzhex7dxo/debs-9b4337.txz?dl=1" | tar xJv
sudo dpkg -i debian/bin/*.deb
systemctl daemon-reload && systemctl restart kubelet


# Bootstrap the k8s master
kubeadm init

