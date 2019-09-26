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


USAGE="
Usage: $0 --kube=v1.16.0 --etcd=3.3.15 --coredns=1.6.2 --pause=3.1

To tag and save docker images of Kubernetes's core components.

-d                                save to this folder
--kube                            core components. kube-apiserver/kube-scheduler/kube-controller-manager/kube-proxy
--etcd                            etcd component.
--coredns                         coredns component.
--pause                           pause component.
--dashboard                       kubernetes-dashboard
--heapster                        heapster-amd64
--heapster-influxdb               heapster-influxdb-amd64
--heapster-grafana                heapster-grafana-amd64
-h|--help                         show this help info
"

function usage() {
	printf "%s\\n" "$USAGE"
}

if [ -z $1 ];then
	usage
	exit 0
fi


# Constants and array for image:version
save_to="."
username=jsonbruce
images=()


# getopt
ARGS=`getopt -o d:h -l kube:,coredns:,etcd:,pause:,dashboard:,heapster:,heapster-influxdb:,heapster-grafana:,help -- "$@"`

if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi
eval set -- "${ARGS}"

while true
do
	case "$1" in
	    -d)
			#echo "Option --kube", $2
			save_to=$2
			shift 2
			;;
		--kube)
			#echo "Option --kube", $2
			image=("kube-apiserver:$2" "kube-controller-manager:$2" "kube-scheduler:$2" "kube-proxy:$2")
			images+=${image[@]}
			shift 2
			;;
		--coredns)
			#echo "Option --coredns, arg $2"
			image="coredns:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		--etcd)
		    #echo "Option --etcd. arg $2"
			image="etcd:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		--pause)
			#echo "Option --pause, arg $2"
			image="pause:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		--dashboard)
			#echo "Option --dashboard, arg $2"
			image="kubernetes-dashboard-amd64:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		--heapster)
			#echo "Option --heapster, arg $2"
			image="heapster-amd64:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		--heapster-influxdb)
			#echo "Option --heapster-influxdb, arg $2"
			image="heapster-influxdb-amd64:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		--heapster-grafana)
			#echo "Option --heapster-grafana, arg $2"
			image="heapster-grafana-amd64:$2"
			images=(${images[@]} $image)
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			break
			;;
		*)
			echo "$1 is not an option!"
			exit 1
			;;
	esac
done

for image in ${images[@]};
do
    docker pull $username/$image
	docker tag $username/$image k8s.gcr.io/$image
    docker save k8s.gcr.io/$image > "$save_to/${image}.tgz"
    docker rmi $username/$image
done
