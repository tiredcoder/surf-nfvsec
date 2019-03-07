# PoC Installation and Configuration: How to

## Kata Stable 1.4 install
https://github.com/kata-containers/documentation/blob/master/install/README.md#manual-installation


NOTE:
https://github.com/kata-containers/runtime/blob/stable-1.4/versions.yaml
https://apisecurity.io/mutual-tls-authentication-vulnerability-in-go-cve-2018-16875
- Kata Containers 1.4.0 is compatible with:
- Kubernetes v1.12.2-00
- CRI-O version "fa540c8e806d28c2cbcd157bdf8acf2b20990ab6" (v1.12.2)
- runc version v1.0.0-rc5
- Golang v1.11.5 instead of v1.11.1


## 0. Prep
- Run all cmds as root!
- Create CentOS 7 host VMs with SELinux and swap disabled.
- Install git, vim, curl, wget, etc.
- Create SSH keys to allow access from master to slave, and from pod to hypervisor (key will be inserted into k8s)


## 1. Add the Kata Containers repository to the package manager, and import the packages signing key
```shell
source /etc/os-release
yum -y install yum-utils
ARCH=$(arch)
KATA_RELEASE=stable-1.4
yum-config-manager --add-repo "http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${KATA_RELEASE}/CentOS_${VERSION_ID}/home:katacontainers:releases:${ARCH}:${KATA_RELEASE}.repo"
```


## 2. Install the Kata Containers packages.
```shell
yum install kata-runtime kata-proxy kata-shim
```
Verify fingerprint before importing the pub. key: 9fdc 0cb6 3708 cf80 3696 e2dc d0b3 7b82 6063 f3ed


## 3. Verify if hardware is supported.
```shell
kata-runtime kata-check
```


## 4. Install container manager: CRI-O
https://github.com/kata-containers/documentation/blob/master/Developer-Guide.md#run-kata-containers-with-kubernetes
https://github.com/kubernetes-sigs/cri-o/blob/release-1.12/tutorial.md

runC:
```shell
wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64
chmod +x runc.amd64
mv runc.amd64 /usr/bin/runc
```

Golang:
```shell
wget https://storage.googleapis.com/golang/go1.11.5.linux-amd64.tar.gz
tar -xvf go1.11.5.linux-amd64.tar.gz -C /usr/local/
mkdir -p $HOME/go/src
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
rm -f go1.11.5.linux-amd64.tar.gz
```

crictl:
```shell
CRICTL_VERSION="v1.12.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz
tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$CRICTL_VERSION-linux-amd64.tar.gz
```

Build crio from source:

Enable EPEL:
```shell
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum update
```
Verify GPG key using: https://getfedora.org/keys/

Install other depen per readme:
```shell
yum install -y \
  gcc \
  make \
  btrfs-progs-devel \
  device-mapper-devel \
  git \
  glib2-devel \
  glibc-devel \
  glibc-static \
  golang-github-cpuguy83-go-md2man \
  gpgme-devel \
  libassuan-devel \
  libgpg-error-devel \
  libseccomp-devel \
  libselinux-devel \
  ostree-devel \
  pkgconfig \
  skopeo-containers

git clone https://github.com/kubernetes-sigs/cri-o --branch=v1.12.2
cd cri-o
make install.tools
make
make install
make install.config
yum update
```


##  5. Config CRI-O
runtime depen:
```shell
yum install -y socat iproute iptables
```

use btrfs for image store:
```shell
yum install -y btrfs-progs
mkfs.btrfs -f /dev/vda3
echo '/dev/vda3   /var/lib/containers/storage   btrfs   defaults   0 0' >> /etc/fstab
mkdir -p /var/lib/containers/storage
mount -a
```

changes in /etc/containers/storage.conf:
```shell
[storage]
driver = "btrfs"
graphroot = "/var/lib/containers/storage"
[storage.options]
#override_kernel_check = "true"
```

changes in /etc/crio/crio.conf:
https://github.com/kubernetes-sigs/cri-o/blob/release-1.12/docs/crio.conf.5.md
```shell
[crio]
root = "/var/lib/containers/storage"
storage_driver = "btrfs"

[crio.image]
registries = [
       "registry.centos.org",
       "docker.io",
]

[crio.runtime]
# We need CRI-O to perform the network namespace management. Otherwise, when the VM starts the network will not be available.
manage_network_ns_lifecycle = true

#runtime = ""
default_runtime = "runc"
#runtime_untrusted_workload = ""
#default_workload_trust = ""

[crio.runtime.runtimes.runc]
runtime_path = "/usr/bin/runc"

[crio.runtime.runtimes.kata-nemu]
runtime_path = "/usr/bin/kata-runtime"
```

Create systemd unit file:
```shell
echo "[Unit]
Description=OCI-based implementation of Kubernetes Container Runtime Interface
Documentation=https://github.com/kubernetes-sigs/cri-o

[Service]
ExecStart=/usr/local/bin/crio
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/crio.service
```


## 6. Start CRI-O
```shell
systemctl daemon-reload
systemctl enable crio
systemctl start crio
```

Verify if cri-o is running:
```shell
systemctl status crio
/usr/local/bin/crictl --runtime-endpoint unix:///var/run/crio/crio.sock version
/usr/local/bin/crictl info
```

Skip CNI plugins bins, k8s will install them.
Use CNI configs (see below) for testing (default bridge network).


## 7. Build and config NEMU
```shell
git clone https://github.com/intel/nemu.git
cd nemu
git fetch origin
git checkout origin/experiment/automatic-removal
```

CentOS gcc is too old (v4.8.5), update from centos-release-scl repo which includes v8.2.1:
```shell
yum install centos-release-scl
yum install devtoolset-8-gcc*
scl enable devtoolset-8 bash
which gcc
gcc --version
```

install build depen:
```shell
yum install -y libcap-ng-devel zlib-devel pixman-devel librbd1-devel libcap-devel libattr-devel
```

build:
```shell
SRCDIR=$PWD ./tools/build_x86_64_virt.sh
```
result bin is at /root/build-x86_64_virt/x86_64_virt-softmmu/qemu-system-x86_64_virt

get OVMF firmware for VM kernel:
```shell
yum install -y jq
mkdir -p /usr/share/nemu
OVMF_URL=$(curl -sL https://api.github.com/repos/intel/ovmf-virt/releases/latest | jq -S '.assets[0].browser_download_url')
curl -o OVMF.fd -L $(sed -e 's/^"//' -e 's/"$//' <<<"$OVMF_URL")
install -o root -g root -m 0640 OVMF.fd /usr/share/nemu/
```

Configure Kata:
edit /usr/share/defaults/kata-containers/configuration.toml:
```shell
[hypervisor.qemu]
#path = "/usr/bin/qemu-lite-system-x86_64"
path = "/root/build-x86_64_virt/x86_64_virt-softmmu/qemu-system-x86_64_virt"
#machine_type = "pc"
machine_type = "virt"
#firmware = ""
firmware = "/usr/share/nemu/OVMF.fd"
#default_memory = 2048
default_memory = 768
```

verify:
```shell
kata-runtime kata-env | grep -A 10 -i hypervisor
```


## 8. Install K8S
https://kubernetes.io/docs/setup/independent/install-kubeadm/
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
https://kubernetes.io/docs/concepts/containers/runtime-class/

add repo:
```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
```

install:
```shell
modprobe br_netfilter
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

K8S_VERSION=1.12.2-0
yum install -y kubelet-$K8S_VERSION kubectl-$K8S_VERSION kubeadm-$K8S_VERSION --disableexcludes=kubernetes
```

config K8S to use CRI-O with the RuntimeClass feature:
```shell
vim /etc/systemd/system/kubelet.service.d/0-crio.conf

[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///var/run/crio/crio.sock --feature-gates=RuntimeClass=true"
```

```shell
vim /etc/sysconfig/kubelet

KUBELET_EXTRA_ARGS=--feature-gates=RuntimeClass=true
```

```shell
systemctl daemon-reload
systemctl enable --now kubelet
```


## 9. Deploy k8s cluster
```shell
vim kubeinit_config.yaml

apiVersion: kubeadm.k8s.io/v1alpha3
kind: InitConfiguration
nodeRegistration:
  criSocket: /var/run/crio/crio.sock
---
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
kubernetesVersion: v1.12.2
networking:
  podSubnet: "10.244.0.0/16"
apiServerExtraArgs:
  feature-gates: RuntimeClass=true
---
apiVersion: kubeadm.k8s.io/v1alpha3
kind: JoinConfiguration
nodeRegistration:
  criSocket: /var/run/crio/crio.sock
```

```shell
kubeadm init --config=kubeinit_config.yaml
```

Deploy slave:
On master:
```shell
kubeadm token create --print-join-command
```
Use that command plus '--cri-socket /var/run/crio/crio.sock' to join cluster


Authenticate to cluster:
```shell
export KUBECONFIG=/etc/kubernetes/admin.conf
```

Install the RuntimeClass CRD:
```shell
wget https://raw.githubusercontent.com/kubernetes/kubernetes/v1.12.2/cluster/addons/runtimeclass/runtimeclass_crd.yaml
kubectl apply -f runtimeclass_crd.yaml
```

create the RuntimeClass resources:
```shell
vim runtimeclassrsc.yaml

apiVersion: node.k8s.io/v1alpha1
kind: RuntimeClass
metadata:
  name: kata-nemu
spec:
  runtimeHandler: kata-nemu
```
```shell
kubectl apply -f runtimeclassrsc.yaml
```

Allow pods to be scheduled on master node:
```shell
kubectl taint node master node-role.kubernetes.io/master:NoSchedule-
```

Set kata label on nodes:
```shell
kubectl label node master kata-containers.io/kata-runtime=true
kubectl label node slave kata-containers.io/kata-runtime=true
```

## 9.5. If needed, tear down K8S cluster:
```shell
kubectl drain master --delete-local-data --force --ignore-daemonsets
kubectl delete node master
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

Use 'crictl rmp #' to remove any leftover pods.

```shell
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /run/flannel
rm -rf /etc/cni/net.d/*
ip link set dev cni0 down
ip link delete cni0
ip link set dev flannel.1 down
ip link delete flannel.1
```

## 10. CNI
Testing only (uses linux bridge, don't use with flannel!):
```shell
sh -c 'cat >/etc/cni/net.d/10-mynet.conf <<-EOF
{
    "cniVersion": "0.2.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.244.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0"  }
        ]
    }
}
EOF'
```

```shell
sh -c 'cat >/etc/cni/net.d/99-loopback.conf <<-EOF
{
    "cniVersion": "0.2.0",
    "type": "loopback"
}
EOF'
```

```shell
systemctl restart crio
crictl info
```

Multus:
Use the master branch, v3.1 is missing patches:
https://github.com/coreos/flannel/issues/733

```shell
git clone https://github.com/intel/multus-cni.git && cd multus-cni
cat ./images/{multus-crio-daemonset.yml,flannel-daemonset.yml} | kubectl apply -f -
```

Slave:
```shell
mkdir -p /opt/cni/bin
```
On master:
```shell
scp /opt/cni/bin/multus slave:/opt/cni/bin/
```

Configure bridge (master and slave!):
https://github.com/containernetworking/plugins/tree/master/plugins/main/bridge
https://github.com/intel/multus-cni/blob/master/doc/how-to-use.md

```shell
echo "DEVICE=underlay_br
NAME=underlay_br
TYPE=Bridge
ONBOOT=yes
NM_CONTROLLED=no
MTU=1500
BOOTPROTO=none
DEFROUTE=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
DHCPV6C=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
STP=no
DELAY=0" > /etc/sysconfig/network-scripts/ifcfg-underlay_br
```

```shell
echo "DEVICE=eth1
NAME=eth1
TYPE=Ethernet
ONBOOT=yes
BRIDGE=underlay_br
NM_CONTROLLED=no
MTU=1500
BOOTPROTO=none
DEFROUTE=no
IPV4_FAILURE_FATAL=no
PROXY_METHOD=none
BROWSER_ONLY=no
IPV6INIT=no
IPV6_AUTOCONF=no
DHCPV6C=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy" > /etc/sysconfig/network-scripts/ifcfg-eth1
```

```shell
systemctl restart network
```

```shell
vim /etc/sysctl.conf

net.ipv6.conf.underlay_br.disable_ipv6 = 1
net.ipv6.conf.eth1.disable_ipv6 = 1
```

```shell
sysctl -p
```

```shell
cat <<EOF | kubectl apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: underlay-conf
spec:
  config: '{
    "cniVersion": "0.3.0",
    "name": "underlay-conf",
    "type": "bridge",
    "bridge": "underlay_br",
    "ipam": {
        "type": "host-local",
        "ranges": [
            [ {
                 "subnet": "10.200.0.0/16",
                 "rangeStart": "10.200.0.100",
                 "rangeEnd": "10.200.255.250",
                 "gateway": "10.200.0.1"
            } ]
        ]
     }
  }'
EOF
```

```shell
kubectl get network-attachment-definitions
```

And also create the bridge on the hypervisor running the K8S VMs!


## 11. Create test pod using kata runtime:
```shell
vim nginx-kata-nemu.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: nginx-kata-nemu
  name: nginx-kata-nemu
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx-kata-nemu
  template:
    metadata:
      labels:
        run: nginx-kata-nemu
      annotations:
        k8s.v1.cni.cncf.io/networks: underlay-conf@underlay
    spec:
      runtimeClassName: kata-nemu
      containers:
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        ports:
        - containerPort: 80
          protocol: TCP
        resources:
          requests:
            cpu: 200m
      nodeSelector:
        kata-containers.io/kata-runtime: 'true'
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-kata-nemu
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: nginx-kata-nemu
  sessionAffinity: None
  type: ClusterIP
```

```shell
kubectl apply -f nginx-kata-nemu.yaml
```

## 12. Verify/Debug
```shell
kubectl get nodes
kubectl describe nodes master|less
kubectl get pods --all-namespaces -o wide
crictl images
crictl pods
crictl ps
crictl logs <container>
kata-runtime list
pgrep -cf runc
pgrep -cf qemu-system-x86_64_virt
```

list net namespaces:
```shell
lsns -t net -u
```

Show proccesses within netns:
```shell
ps -eo netns,pid,ppid,user,args --sort netns | grep #
```

Enter netns of pid:
```shell
nsenter -t 5737 -n /bin/bash
```

show detailed info (macvlan mode):
```shell
ip -d link show
```

kata info:
```shell
kata-collect-data.sh
```


## 13. GUIs:
Dashboard:
```shell
vim adminuser.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```

```shell
kubectl apply -f adminuser.yaml
```

```shell
wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f kubernetes-dashboard.yaml
```

```shell
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
kubectl proxy
```

Open browser (via SSH tunnel):
http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/


k8s-graph:
```shell
git clone https://github.com/rilleralle/k8s-graph.git
```

Edit k8s-graph.yaml (use same service account as dashboard):
```shell
spec:
  serviceAccountName: admin-user
```

```shell
kubectl apply -f k8s-graph.yaml
```

## 14. Building the images
```shell
docker build .
docker tag <ID> rjos3/surf-rqlite
docker login
docker push rjos3/surf-rqlite

docker build .
docker tag <ID> rjos3/surf-ctrl
docker login
docker push rjos3/surf-ctrl

docker build .
docker tag <ID> rjos3/surf-vnf-tcpdump
docker login
docker push rjos3/surf-vnf-tcpdump
```


## 15. Insert key pair into k8s
```shell
kubectl create secret generic ssh-key-lb --from-file=ssh-privatekey=ssh_key_lb.key --from-file=ssh-publickey=ssh_key_lb.pub
```
Then configure the deployments (.yaml files) to use the key.
