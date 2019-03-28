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


KUBE_APISERVER=kube-apiserver
KUBE_SCHEDULER=kube-scheduler
KUBE_CONTROLLER_MANAGER=kube-controller-manager
KUBE_PROXY=kube-proxy
COREDNS=coredns
ETCD=etcd
PAUSE=pause
TILLER=tiller

VERSION_OLD="v1.13.1"
VERSION_NEW="v1.14.0"
VERSION_COREDNS="1.3.1"
VERSION_ETCD="3.3.10"
VERSION_PAUSE="3.1"
VERSION_TILLER="v2.13.1"

URL_EDIT="https://cloud.docker.com/repository/docker/%s/%s/builds/edit"
USERNAME="jsonbruce"

# Dict for branch:version
declare -A target
target=([$KUBE_APISERVER]=$VERSION_NEW \
        [$KUBE_SCHEDULER]=$VERSION_NEW \
        [$KUBE_CONTROLLER_MANAGER]=$VERSION_NEW \
        [$KUBE_PROXY]=$VERSION_NEW \
        [$COREDNS]=$VERSION_COREDNS \
        [$ETCD]=$VERSION_ETCD \
        [$PAUSE]=$VERSION_PAUSE \
		[$TILLER]=$VERSION_TILLER
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
        version=${target[$branch]}
        file_name="$branch-$version"
        echo "Upgrade to" $file_name

        unset files
        files=(`ls -1`)
        if echo "${files[@]}" | grep -w "$file_name" &>/dev/null; then
            echo "Already upgraded."
        else
            result=(${result[@]} $branch)
            v=${files[0]:${#branch}+1}
            cp -r ${files[0]} $file_name
            sed -i "s/${v}/${version}/" $branch-$version/Dockerfile
            git add .
            git commit -m "$branch:$version"
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
