### Basic Kubernetes Cluster on OpenStack

This `terraform` configuration can create a basic, multi-node k8s cluster on OpenStack. It uses [kubeadm](https://github.com/kubernetes/kubernetes/tree/master/cmd/kubeadm) to provision a securely bootstrapped cluster, issuing a single command on each node.

---
### Instructions

#### Step 1: Prerequisites
##### Terraform
First, make sure you have installed `terraform` on your local machine and that it's on your path.
##### Credentials
Download your OpenStack RC v2.0 file from the OpenStack dashboard and **source** it, e.g.:

```{bash}
source k8s-openrc.sh
```
##### OS image for the nodes
Next, create a `Ubuntu 16.04` image in OpenStack and call it `Ubuntu Xenial` (or change the image name in the `config.tf` at step 3). You can use this URL:

```{URL}
https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.vmdk
```
##### Kubernetes client
Finally, get `kubectl` (the k8s command-line client) and put it on your system PATH, e.g.:
```{bash}
curl -O https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kubectl
sudo cp kubectl /usr/local/bin
```

---
#### Step 2: Secure access to the instances
Generate a key-pair which will be your secret for accessing the OpenStack cluster nodes:
```{bash}
ssh-keygen -t rsa
```

Terraform requires a non-password-protected private key, so you need to "unlock" your private key in case you used a password during the generation, e.g.:
```{bash}
openssl rsa -in ~/.ssh/id_rsa -out ~/.ssh/[non-password key name]
```
Remember the path to this key as you will need it in the next step.

---
#### Step 3: Configuration
Set values for the following variables in `config.tf`:
* `bootstrap_token`: a randomized string of your choice, following the format `30f54b.f400ed0dc93169df`. Both parts should be valid HEX strings, separated by a dot.
* `ssh_key_file`: should point to the non-password private key (e.g. from step 3) that will be used to create an OpenStack key pair.
* `os_project_id`: set to the ID of your OpenStack project.

Feel free to change any of the configuration in `config.tf` to suite your needs :)

---
#### Step 4: Run it!
Execute:
```{bash}
terraform apply
```
in the directory of this README file.

If everything went well, you should be able to run `kubectl` as a proxy on your machine and (after 2-3 minutes or so) and access the [k8s dashboard](https://github.com/kubernetes/dashboard) on `http://localhost:8001/ui`:
```{bash}
kubectl proxy
```
You can also run `kubectl` in the command line to check the status of all pods.

---
#### Troubleshooting
If you cannot connect to dashboard, but the all pods are running, it's probably an issue with the POD overlay network. Try recreating it (run from this directory):

```
kubectl delete ds kube-flannel-ds --namespace=kube-system
kubectl apply -f addons/kube-flannel.yaml
```
