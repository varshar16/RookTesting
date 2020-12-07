#!/bin/bash -e

device_format=0
# if lvs true then proceed
if [[ "$(sudo lvs)" ]]; then
        echo "Formatting in progress"
        sudo lvremove vg_nvme -y
        # Get nvme name
        device_name="$(sudo lsblk -f | awk '/nvme/ {print $1}')"
        echo "$device_name is the device name, proceeding to remove fs"
        sudo wipefs -a /dev/$device_name
        if [[ !"$(sudo lsblk -f | awk '/nvme/ {print $2}')" ]]; then
                device_format=1
        else
                echo "Erasing fs failed"
        fi
else
        echo "No, device to reformat"
fi

if [ $device_format ]; then
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
        echo "Cloning rook repo"
        git clone https://github.com/rook/rook.git
        if [ -a rook/rook ]; then
                echo "Cloned successfully"
        fi
        echo "Using podman as driver"
        minikube start --driver=podman
        minikube ssh "sudo apt-get update && sudo apt-get install lvm2 -y"

        if [[ "$(kubectl get pods --all-namespaces)" ]]; then
                echo "Deploying rook operator"
                cd ~/rook/cluster/examples/kubernetes/ceph
                kubectl create -f crds.yaml -f common.yaml -f operator.yaml
                sleep 2m
                if [[ "$(kubectl get pods -n rook-ceph)" ]]; then
                        echo "Deploying ceph clusters"
                        sed -i  "s/\("useAllDevices" *: *\).*/\1false/" cluster-test.yaml
                        sed -i "s/#deviceFilter:/deviceFilter: $device_name/" cluster-test.yaml
                        sed -i '/\deviceFilter/a \   \ config: \n \    \ osdsPerDevice: \"3\" ' cluster-test.yaml
                        kubectl create -f cluster-test.yaml -f toolbox.yaml
                else
                        echo "Failed rook operator deployment"
                fi
        else
                echo "Error kube pods not started"
        fi
fi
