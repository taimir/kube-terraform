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


# Bootstrap the k8s master
sudo kubeadm init --pod-network-cidr 10.3.0.0/16 > bootstrap_output.log
node_command=$(cat bootstrap_output.log | tail -n 1)
echo "Bootstrap output:"
cat bootstrap_output.log
echo "Run on the nodes: ${node_command}"

# Create pod overlay
kubectl create -f /home/ubuntu/addons/flannel-cfg.yaml
kubectl create -f /home/ubuntu/addons/flannel-ds.yaml
