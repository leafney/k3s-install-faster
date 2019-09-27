#!/bin/sh
#set -u

K3S_MASTER_IP="192.168.33.10"

k3s_type="master"

if [ ! -n "$1" ]; then
    echo "[info] args is empty,set default value master"
else
    k3s_type=$1
fi

cd /tmp

# firewalld
echo "[info] disable firewalld"
sudo systemctl disable firewalld 
sudo systemctl stop firewalld

if [ -e "./k3s" ]; then
    echo "[info] found k3s ,move k3s to /usr/local/bin/"
    sudo cp ./k3s /usr/local/bin
    echo "[info] chmod for k3s"
    sudo chmod +x /usr/local/bin/k3s
else
    echo "[info] can not found k3s, will download it"
fi

if [ "$k3s_type" == "node" ]; then
    echo "[info] install for node0X"

    if [ -e "./k3s.token" ]; then
        echo "[info] get k3s token file"
        K3S_TOKEN=$(sudo cat ./k3s.token)
    else
        echo "[info] can not found k3s token file"
    fi

    echo "[info] install for node0X"
    curl -sfL https://get.k3s.io | K3S_URL=https://${K3S_MASTER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -

else
    echo "[info] install for master"
    
    # install k3s by install.sh
    curl -sfL https://get.k3s.io | sh -
    
    sleep 5s

    if [ ! -e "/etc/systemd/system/k3s.service" ]; then
        echo "[info] k3s.service can not installed"

        echo "[info] install k3s.service by local file"
        sudo sh ./install.sh
    fi

    sudo sed -i 's/server/& --write-kubeconfig-mode 644/' /etc/systemd/system/k3s.service
    sudo systemctl daemon-reload
    sudo systemctl restart k3s

    echo "[info] save k3s cluster token to k3s.token"
    sudo echo `sudo cat /var/lib/rancher/k3s/server/node-token` > ./k3s.token

    echo "[info] show k3s cluster status"
    kubectl get node
fi

if [ -e "pause.tar" ]; then
    echo "[info] load pause:3.1 image"
    sudo env PATH=$PATH ctr image import pause.tar
fi

echo "done"