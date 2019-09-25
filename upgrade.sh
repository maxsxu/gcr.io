#!/bin/bash


#########################################################################
#   Copyright (C) 2019 All rights reserved.
#   
#   FILE: upgrade.sh
#   AUTHOR: Max Xu
#   MAIL: xuhuan@live.cn
#   DATE: 2019.03.27 15:41:55
#
#########################################################################

basepath=$(cd `dirname $0`; pwd)
echo $basepath
echo "${basepath##*/}"
if [ "${basepath##*/}" = "gcr.io" ];then
    echo "Please run this script out of git repo!"
    exit
fi


USAGE="
Usage: $0 -n|--nodes node_list_file [-u|--user user -p|--port port -d|--dir dst_dir] file1 [file2 file3 ...]

Deploy Files to each node in cluster.

node_list_file                  a file. node name or ip per line
user                            username of each node
port                            ssh port of each node(default to 22)
dst_dir                         directory in node  to be deployed
file[n]                         file or directory list seperated by blank
"

function usage() {
	printf "%s\\n" "$USAGE"
}

if [ -z $1 ];then
	usage
	exit 0
fi

# Constants
KUBE_APISERVER=kube-apiserver
KUBE_SCHEDULER=kube-scheduler
KUBE_CONTROLLER_MANAGER=kube-controller-manager
KUBE_PROXY=kube-proxy
COREDNS=coredns
ETCD=etcd
PAUSE=pause

VERSION_NEW="v1.16.0"
VERSION_COREDNS="1.3.1"
VERSION_ETCD="3.3.10"
VERSION_PAUSE="3.1"

URL_EDIT="https://cloud.docker.com/repository/docker/%s/%s/builds/edit"
USERNAME="jsonbruce"

# getopt
ARGS=`getopt -o k:c:e:p: -l kube:,coredns:,etcd:,pause:,help -- "$@"`

if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi
eval set -- "${ARGS}"

while true
do
	case "$1" in
		-k|--kube)
			echo "Option --kube", $2
			VERSION_NEW=$2
			shift 2
			;;
		-c|--coredns)
			echo "Option --coredns, arg $2"
			VERSION_COREDNS=$2
			shift 2
			;;
		-e|--etcd)
		    echo "Option --etcd. arg $2"
			VERSION_ETCD=$2
			shift 2
			;;
		-p|--pause)
			echo "Option --pause, arg $2"
			VERSION_PAUSE=$2
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

# Dict for branch:version
declare -A target
target=([$KUBE_APISERVER]=$VERSION_NEW \
        [$KUBE_SCHEDULER]=$VERSION_NEW \
        [$KUBE_CONTROLLER_MANAGER]=$VERSION_NEW \
        [$KUBE_PROXY]=$VERSION_NEW \
        [$COREDNS]=$VERSION_COREDNS \
        [$ETCD]=$VERSION_ETCD \
        [$PAUSE]=$VERSION_PAUSE
)

# Array for statistical
declare -a result
result=()

# Workdir
cd ~/Develop/gcr.io

# main
for branch in $(echo ${!target[*]})
do
        git checkout $branch
        version_new=${target[$branch]}
        file_name="$branch:$version_new"
        echo "Upgrade to" $file_name

        unset files
        files=(`ls -1`)
        if echo "${files[@]}" | grep -w "$file_name" &>/dev/null; then
            echo "Already upgraded."
        else
            result=(${result[@]} $branch)
            version_old=${files[0]:${#branch}+1}
            cp -r ${files[0]} $file_name
            sed -i "s/${version_old}/${version_new}/" $file_name/Dockerfile
            git add .
            git commit -m "$file_name"
            git push origin $branch
        fi
        echo
done

echo "Congratulations! There are ${#result[@]} Dcoker Images have upgraded to the newest version."
echo "Please follow the urls below to Configure Automated Builds at cloud.docker.com:"
echo
for branch in ${result[@]}
do
    url=$(printf "$URL_EDIT" $USERNAME $branch)
    echo -e "\033[34m[$branch]:\033[0m"   "\033[32m$url\033[0m"
done
