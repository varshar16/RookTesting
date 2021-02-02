#!/bin/bash -e

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "/home/varsha/go/src/github.com/rook/rook/build/common.sh"

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

function copy_image_to_cluster() {
    local build_image=$1
    local final_image=$2
    docker save "${build_image}" | (eval "$(minikube docker-env --shell bash)" && docker load && docker tag "${build_image}" "${final_image}")
}

function copy_images() {
    if [[ "$1" == "" || "$1" == "ceph" ]]; then
      echo "copying ceph images"
      copy_image_to_cluster "${BUILD_REGISTRY}/ceph-amd64" rook/ceph:master
      # uncomment to push the nautilus image when needed
      #copy_image_to_cluster ceph/ceph:v15 ceph/ceph:v15
    fi
}

# configure minikube
MEMORY=${MEMORY:-"3000"}

# use vda1 instead of sda1 when running with the libvirt driver
DISK="vda1"

case "${1:-}" in
  up)
    echo "starting minikube with kubeadm bootstrapper"
    minikube start --memory="${MEMORY}" -b kubeadm --insecure-registry="192.168.0.138:5000"
    wait_for_ssh
    # create a link so the default dataDirHostPath will work for this environment
    minikube ssh "sudo mkdir -p /mnt/${DISK}/rook/ && sudo ln -sf /mnt/${DISK}/rook/ /var/lib/"
    # Temporary key update, it should be removed
    #minikube ssh "sudo apt-get update 2> /dev/null" || true
    #minikube ssh "sudo sh -c \"echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list\""
    #minikube ssh "sudo apt-get install wget -y"
    #minikube ssh "wget -q https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key -O- | sudo apt-key add -"
    minikube ssh "sudo apt-get update && sudo apt-get install lvm2 -y"
    copy_images "$2"
    ;;
  down)
    minikube stop
    ;;
  ssh)
    echo "connecting to minikube"
    minikube ssh
    ;;
  update)
    copy_images "$2"
    ;;
  clean)
    minikube delete
    sudo sgdisk --zap-all /dev/vdb
    ;;
  *)
    echo "usage:" >&2
    echo "  $0 up [ceph]" >&2
    echo "  $0 down" >&2
    echo "  $0 clean" >&2
    echo "  $0 ssh" >&2
    echo "  $0 update [ceph]" >&2
esac
