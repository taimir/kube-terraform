#!/bin/bash
kubectl config set-cluster openstack --server=https://$2 --insecure-skip-tls-verify=true
kubectl config set-credentials admin --token=`echo $1 |  cut -d '.' -f 2`
kubectl config set-context openstack --cluster=openstack --user=admin
kubectl config use-context openstack
