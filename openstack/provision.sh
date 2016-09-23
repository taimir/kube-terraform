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
sudo docker run -v /usr/local:/target gcr.io/kubeadm/installer
sudo systemctl daemon-reload && sudo systemctl enable kubelet && sudo systemctl restart kubelet
