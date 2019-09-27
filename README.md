### vagrant环境配置k3s集群

**k3s-install-faster**让k3s安装**更快一点儿**

#### 初始化

系统：CentOS7

```
$ vagrant up
$ vagrant status
```

#### k3s-master

```
vagrant ssh k3s-master

$ sudo vi /etc/ssh/sshd_config

PasswordAuthentication yes
#PermitEmptyPasswords no
#PasswordAuthentication no

$ sudo systemctl restart sshd

## 通过ftp上传所需文件 
## 或
## git clone 该项目

$ ls
install.sh  k3s  pause.tar

## <<<<<<系统环境配置可选>>>>>>
$ sudo vi /etc/hosts

192.168.33.10 k3s-master
192.168.33.11 k3s-node01
192.168.33.12 k3s-node02

$ sudo su -

# setenforce 0
# vi /etc/selinux/config
# swapoff -a
# vi /etc/fstab
注释 swap 一行

$ exit
## <<<<<<系统环境配置可选>>>>>>


$ sudo systemctl disable firewalld && sudo systemctl stop firewalld

$ sudo cp ./k3s /usr/local/bin/

$ sudo chmod +x /usr/local/bin/k3s

$ export INSTALL_K3S_SKIP_DOWNLOAD=true && sudo sh ./install.sh

## 查看使用的网卡 -- eth1
$ ip addr | more

$ sudo sed -i 's/server/& --write-kubeconfig-mode 644 --flannel-iface eth1/' /etc/systemd/system/k3s.service

$ sudo systemctl daemon-reload && sudo systemctl restart k3s

$ kubectl get node

$ sudo env PATH=$PATH ctr image import pause.tar

$ sudo cat /var/lib/rancher/k3s/server/node-token

K107e6662155f2db5fc61c465df32a4a023b99fece618996607e46dd2c7add81c06::node:8b245f2de605789392753dadc7eb502c

$ exit
```

#### k3s-node0X

```
➜ vagrant ssh k3s-node01


$ sudo vi /etc/ssh/sshd_config

PasswordAuthentication yes
#PermitEmptyPasswords no
#PasswordAuthentication no

$ sudo systemctl restart sshd

## 通过ftp上传所需文件
## 或
## git clone 该项目

$ ls
install.sh  k3s  pause.tar

$ sudo systemctl disable firewalld && sudo systemctl stop firewalld
$ sudo cp ./k3s /usr/local/bin/
$ sudo chmod +x /usr/local/bin/k3s

## <<<<<<这里发现一个小bug>>>>>>

即使按照 `curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=XXX sh -` 来执行，最后创建的 k3s.service 中
```
ExecStart=/usr/local/bin/k3s \
    server \
```
可以看到，传递的参数并没有生效。所以这里采用先默认安装，再修改的方式。

## <<<<<<这里发现一个小bug>>>>>>

$ export INSTALL_K3S_SKIP_DOWNLOAD=true && sudo sh ./install.sh

## 查看使用的网卡 -- eth1
$ ip addr | more

$ sudo vi /etc/systemd/system/k3s.service

server <<修改成>> agent --server https://192.168.33.10:6443 --token K107e6662155f2db5fc61c465df32a4a023b99fece618996607e46dd2c7add81c06::node:8b245f2de605789392753dadc7eb502c --flannel-iface eth1

$ sudo systemctl daemon-reload && sudo systemctl restart k3s

$ sudo env PATH=$PATH ctr image import pause.tar

$ sudo reboot
```

#### 查看集群状态

```
$ vagrant ssh k3s-master

$ kubectl get node
```

#### 关于vagrant双网卡问题

注意：由于vagrant创建的虚拟机必须带有一个默认的NAT网卡，所以会因为双网卡的问题导致k3s无法实现集群间的联通。因为flannel默认是选择第一个网卡进行连接的。

可以通过设置项 `--flannel-iface eth1` 来指定使用的网卡名称。

#### 一个示例

`nginx-test.yaml`:
```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - name: http
    port: 8080
    targetPort: 80

```

通过命令 `kubectl get svc` 查看端口。

-----
