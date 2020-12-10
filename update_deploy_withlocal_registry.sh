#!/bin/bash -e

localregistry="$(less /etc/hosts | awk '/smithi/ {print $1}'):5000"
device_name="$(sudo lsblk -f | awk '/nvme/ {print $1}')"

function copy_image_to_cluster() {
    local build_image=$1
    local final_image=$2
    echo "build image $build_image and final image $final_image"
    #podman save -o "${build_image}"
    local DOCKERCMD="podman"
    local docker_env_tag="${DOCKERCMD}-env"
    echo "$docker_env_tag"
    sudo ${DOCKERCMD} save "${build_image}" | \
        (eval "$(minikube ${docker_env_tag} --shell bash)" && \
        ${DOCKERCMD} load && \
        ${DOCKERCMD} tag "${build_image}" "${final_image}")
}

function install_minikube() {
        echo "starting kubectl installation"
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
        if [[ "$(kubectl version --client)" ]]; then
                echo "kubectl successfully installed"
        else
                echo "kubectl installation failed"
                exit
        fi
        echo "starting minikube installation"
        curl -Lo minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64" && chmod +x minikube
        sudo install minikube /usr/local/bin/
        if [[ "$(minikube version)" ]]; then
                echo "minikube successfully installed"
        else
                echo "minikube installation failed"
                exit
        fi
        rm -rf minikube
}

function start_minikube() {
        echo "Using podman as driver"
        #minikube start --driver=podman --insecure-registry="$localregistry"
        #wait_for_ssh
	#minikube ssh "sudo apt-get update && sudo apt-get install lvm2 -y"
        echo "copying ceph images"
	minikube ssh "docker pull 172.21.15.14:5000/build-168ce04b/ceph-amd64:latest && docker tag  172.21.15.14:5000/build-168ce04b/ceph-amd64:latest  rook/ceph:master"
        #copy_image_to_cluster "${BUILD_REGISTRY}/ceph-amd64" rook/ceph:master
        # uncomment to push the nautilus image when needed
        #copy_image_to_cluster ceph/ceph:v15 ceph/ceph:v15
        if [[ "$(kubectl get pods --all-namespaces)" ]]; then
                echo "Deploying rook operator"
                cd ~/go/src/github.com/rook/rook/cluster/examples/kubernetes/ceph
                kubectl create -f crds.yaml -f common.yaml -f operator.yaml
                sleep 2m
                if [[ "$(kubectl get pods -n rook-ceph)" ]]; then
                        echo "Deploying ceph clusters"
                        #sed -i "s|ceph/ceph:v15|${localregistry}/ceph/ceph:latest|g" cluster-test.yaml
                        # sed -i  "s/\("useAllDevices" *: *\).*/\1false/" cluster-test.yaml
                        #sed -i "s/#deviceFilter:/deviceFilter: $device_name/" cluster-test.yaml
                        #sed -i '/\deviceFilter/a \   \ config: \n \    \ osdsPerDevice: \"3\" ' cluster-test.yaml
			kubectl create -f cluster-test.yaml
                else
                        echo "Failed rook operator deployment"
                fi
        else
                echo "Error kube pods not started"
        fi

}

function wait_for_ssh() {
    local tries=100
    while (( tries > 0 )) ; do
        if minikube ssh echo connected &> /dev/null ; then
            return 0
        fi
        tries=$(( tries - 1 ))
        sleep 0.1
    done
    echo ERROR: ssh did not come up >&2
    exit 1
}

function install_rook() {
        #wget https://golang.org/dl/go1.15.6.linux-amd64.tar.gz
        #sudo tar -C /usr/local -xzf go1.15.6.linux-amd64.tar.gz
        #export PATH=$PATH:/usr/local/go/bin
        go version
        #go get github.com/rook/rook
        cd ~/go/src/github.com/rook/rook
        echo "building ceph images"
        #make IMAGES="ceph" build
        scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	echo "script source is $scriptdir"
        #source "${scriptdir}/../../build/common.sh"
	ls ~/go/src/github.com/rook/rook/build/common.sh
	pwd
	source "~/go/src/github.com/rook/rook/build/common.sh"
}


#install_minikube
#install_rook
start_minikube
