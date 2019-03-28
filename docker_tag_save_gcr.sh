#!/bin/bash


#########################################################################
#   Copyright (C) 2018 All rights reserved.
#   
#   FILE: docker_tag_save_gcr.sh
#   AUTHOR: Max Xu
#   MAIL: xuhuan@live.cn
#   DATE: 10/16/2018    TIME:19:45:56
#
#########################################################################


username=jsonbruce
images=("kube-apiserver:v1.14.0" "kube-controller-manager:v1.14.0" "kube-scheduler:v1.14.0" "kube-proxy:v1.14.0" "pause:3.1" "etcd:3.3.10" "coredns:1.3.1" \
     	"kubernetes-dashboard-amd64:v1.10.1" "heapster-amd64:v1.5.4" "heapster-influxdb-amd64:v1.5.2" "heapster-grafana-amd64:v5.0.4" \
		"tiller:v2.13.1")

for image in ${images[@]};
do
    docker pull $username/$image
	if [[ $image == tiller* ]]
	then
		docker tag $username/$image gcr.io/kubernetes-helm/$image
        docker save gcr.io/kubernetes-helm/$image > $1/"${image}.tgz"
	else
		docker tag $username/$image k8s.gcr.io/$image
        docker save k8s.gcr.io/$image > $1/"${image}.tgz"
	fi
    docker rmi $username/$image
done
