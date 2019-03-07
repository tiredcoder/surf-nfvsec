# Results PoC example run
```shell
Starting k8s deployment script!

Deploying...

rqlite database cluster...
service/rqlite-cluster created
deployment.apps/rqlite-leader created
deployment.apps/rqlite-node created

SURF NFV Controller...
deployment.apps/surf-nfv-controller created
service/surf-nfv-controller created
service/surf-nfv-controller-nodeip created

Init DB
Database initialized.

VNF tcpdump...
deployment.apps/surf-vnf-tcpdump created

Inserting test values...
Inserting edu
123

DB Content:
edu:
[{"id": 1, "ip": "10.200.0.11", "name": "UvA"}, {"id": 2, "ip": "10.200.0.12", "name": "ROC"}, {"id": 3, "ip": "10.200.0.13", "name": "HBO"}]
vnf:
[{"class": "FaaS", "id": 1, "ip": "10.200.0.103"}]

Please insert rule and generate traffic.
Done!
```

```shell
[root@master rp2]# curl --header "Content-Type: application/json" \
>   --request PUT \
>   --data '{"edu_ip":"10.200.0.11","vnf_ip":"10.200.0.103"}' \
>   http://192.168.122.17:30007/api/rules
1[root@master rp2]# 
```

```shell
[root@master rp2]# kubectl get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE
rqlite-leader-5bd7f85775-hvfv5         1/1     Running   0          3m8s    10.244.1.8     slave    <none>
rqlite-node-67488b8964-8rw79           1/1     Running   0          2m48s   10.244.0.190   master   <none>
rqlite-node-67488b8964-t6gkk           1/1     Running   0          2m48s   10.244.1.9     slave    <none>
surf-nfv-controller-7894968775-v28qv   1/1     Running   0          2m26s   10.244.1.10    slave    <none>
surf-nfv-controller-7894968775-zklfg   1/1     Running   0          2m26s   10.244.0.191   master   <none>
surf-vnf-tcpdump-8d5fff4b6-b8qvd       1/1     Running   0          2m1s    10.244.1.11    slave    <none>
```

```shell
[root@slave ~]# crictl pods
POD ID              CREATED             STATE               NAME                                   NAMESPACE           ATTEMPT
f53a0967936c5       2 minutes ago       Ready               surf-vnf-tcpdump-8d5fff4b6-b8qvd       default             0
4fb2aa830d426       2 minutes ago       Ready               surf-nfv-controller-7894968775-v28qv   default             0
a7b4ba0cb80de       3 minutes ago       Ready               rqlite-node-67488b8964-t6gkk           default             0
e1b8004f5778e       3 minutes ago       Ready               rqlite-leader-5bd7f85775-hvfv5         default             0
b4b15c9138eef       About an hour ago   Ready               kube-multus-ds-amd64-25jpb             kube-system         0
6e76e98d8218f       About an hour ago   Ready               kube-flannel-ds-amd64-dffsf            kube-system         0
3197d384fcbce       About an hour ago   Ready               kube-proxy-bhm87                       kube-system         0
```

```shell
[root@slave ~]# crictl ps
CONTAINER ID        IMAGE                                                                                                 CREATED             STATE               NAME                  ATTEMPT             POD ID
95b810b87a4dd       801b561828df193d0557ca61013e665334703d70c53be89f0006c45f8049fb8c                                      2 minutes ago       Running             surf-vnf-tcpdump      0                   f53a0967936c5
6c5d9f54daec6       docker.io/rjos3/surf-ctrl@sha256:88f095a196bf8623f748f5af23a4276cb812661a47d80742dfbcf159baefee1b     2 minutes ago       Running             surf-nfv-controller   0                   4fb2aa830d426
6900eb94450a2       docker.io/rjos3/surf-rqlite@sha256:3121357fb0974dd384886748ee03e6be7ff63897916a8f11f913e2b71f78c9df   3 minutes ago       Running             rqlite-node           0                   a7b4ba0cb80de
e8066a67731d8       docker.io/rjos3/surf-rqlite@sha256:3121357fb0974dd384886748ee03e6be7ff63897916a8f11f913e2b71f78c9df   3 minutes ago       Running             rqlite-leader         0                   e1b8004f5778e
19237cedf036c       docker.io/nfvpe/multus@sha256:0a45fff0fa48853a384e4c40400eb39aea7840113ac8cbf4de2eacf4f3d8ad53        About an hour ago   Running             kube-multus           0                   b4b15c9138eef
75bcf4edf0adf       quay.io/coreos/flannel@sha256:88f2b4d96fae34bfff3d46293f7f18d1f9f3ca026b4a4d288f28347fcb6580ac        About an hour ago   Running             kube-flannel          0                   6e76e98d8218f
62b38898d66ee       k8s.gcr.io/kube-proxy@sha256:c4733855f17c25e5bfe0b23e556aa5f9757ce561507c952db680e14e721a40f2         About an hour ago   Running             kube-proxy            0                   3197d384fcbce
```

```shell
[root@slave ~]# kata-runtime list
ID                                                                 PID         STATUS      BUNDLE                                                                                                               CREATED                          OWNER
f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867   30326       running     /run/containers/storage/btrfs-containers/f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867/userdata   2019-02-27T15:26:19.50774328Z    #0
95b810b87a4dd1641d2c15586f15b88c7870ee68d52e397f36b2c5d039d7c88f   30465       running     /run/containers/storage/btrfs-containers/95b810b87a4dd1641d2c15586f15b88c7870ee68d52e397f36b2c5d039d7c88f/userdata   2019-02-27T15:26:20.525327112Z   #0
```

```shell
[root@slave ~]# pgrep -af nemu
30245 /root/build-x86_64_virt/x86_64_virt-softmmu/qemu-system-x86_64_virt -name sandbox-f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867 -uuid a1d19fe2-356e-40fa-b2e6-fad73456f46e -machine virt,accel=kvm,kernel_irqchip,nvdimm -cpu host,pmu=off -qmp unix:/run/vc/vm/f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867/qmp.sock,server,nowait -m 768M,slots=10,maxmem=4970M -device pcie-pci-bridge,bus=pcie.0,id=pcie-bridge-0,addr=2,romfile= -device virtio-serial-pci,disable-modern=true,id=serial0,romfile= -device virtconsole,chardev=charconsole0,id=console0 -chardev socket,id=charconsole0,path=/run/vc/vm/f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867/console.sock,server,nowait -device nvdimm,id=nv0,memdev=mem0 -object memory-backend-file,id=mem0,mem-path=/usr/share/kata-containers/kata-containers-image_clearlinux_1.4.2_agent_b5efce24832.img,size=536870912 -device virtio-scsi-pci,id=scsi0,disable-modern=true,romfile= -object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng,rng=rng0,romfile= -device virtserialport,chardev=charch0,id=channel0,name=agent.channel.0 -chardev socket,id=charch0,path=/run/vc/vm/f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867/kata.sock,server,nowait -device virtio-9p-pci,disable-modern=true,fsdev=extra-9p-kataShared,mount_tag=kataShared,romfile= -fsdev local,id=extra-9p-kataShared,path=/run/kata-containers/shared/sandboxes/f53a0967936c57b05fdc0f95103e242f55c03e0f250e29bb85fc9afafc1d2867,security_model=none -netdev tap,id=network-0,vhost=on,vhostfds=3,fds=4 -device driver=virtio-net-pci,netdev=network-0,mac=0a:58:0a:f4:01:0b,disable-modern=true,mq=on,vectors=4,romfile= -netdev tap,id=network-1,vhost=on,vhostfds=5,fds=6 -device driver=virtio-net-pci,netdev=network-1,mac=0a:58:0a:c8:00:67,disable-modern=true,mq=on,vectors=4,romfile= -global kvm-pit.lost_tick_policy=discard -vga none -no-user-config -nodefaults -nographic -daemonize -kernel /usr/share/kata-containers/vmlinuz-4.14.67.22-6.1.container -append tsc=reliable no_timer_check rcupdate.rcu_expedited=1 i8042.direct=1 i8042.dumbkbd=1 i8042.nopnp=1 i8042.noaux=1 noreplace-smp reboot=k console=hvc0 console=hvc1 iommu=off cryptomgr.notests net.ifnames=0 pci=lastbus=0 root=/dev/pmem0p1 rootflags=dax,data=ordered,errors=remount-ro rw rootfstype=ext4 quiet systemd.show_status=false panic=1 nr_cpus=4 init=/usr/lib/systemd/systemd systemd.unit=kata-containers.target systemd.mask=systemd-networkd.service systemd.mask=systemd-networkd.socket -bios /usr/share/nemu/OVMF.fd -smp 1,cores=1,threads=1,sockets=1,maxcpus=4
```

```shell
[root@master rp2]# kubectl logs surf-nfv-controller-7894968775-v28qv
# 192.168.122.1:22 SSH-2.0-OpenSSH_7.4
# 192.168.122.1:22 SSH-2.0-OpenSSH_7.4
# 192.168.122.1:22 SSH-2.0-OpenSSH_7.4
 * SURF NFV Controller
 * Database server: rqlite-cluster (rqlite)
 * Serving Flask app "nfv_controller" (lazy loading)
 * Environment: production
   WARNING: Do not use the development server in a production environment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
10.244.0.0 - - [27/Feb/2019 15:26:06] "PUT /api/edu HTTP/1.1" 200 -
10.244.0.0 - - [27/Feb/2019 15:26:36] "GET /api/vnf HTTP/1.1" 200 -
```

```shell
[root@master rp2]# kubectl logs surf-nfv-controller-7894968775-zklfg
# 192.168.122.1:22 SSH-2.0-OpenSSH_7.4
# 192.168.122.1:22 SSH-2.0-OpenSSH_7.4
# 192.168.122.1:22 SSH-2.0-OpenSSH_7.4
 * SURF NFV Controller
 * Database server: rqlite-cluster (rqlite)
 * Serving Flask app "nfv_controller" (lazy loading)
 * Environment: production
   WARNING: Do not use the development server in a production environment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
10.244.0.1 - - [27/Feb/2019 15:23:40] "PUT /api/db/init HTTP/1.1" 200 -
10.244.0.1 - - [27/Feb/2019 15:23:45] "PUT /api/edu HTTP/1.1" 200 -
10.244.0.1 - - [27/Feb/2019 15:23:46] "PUT /api/edu HTTP/1.1" 200 -
10.244.0.1 - - [27/Feb/2019 15:23:46] "GET /api/edu HTTP/1.1" 200 -
10.244.1.11 - - [27/Feb/2019 15:24:02] "PUT /api/vnf HTTP/1.1" 200 -
bash: warning: setlocale: LC_ALL: cannot change locale (C.UTF-8)
/bin/sh: warning: setlocale: LC_ALL: cannot change locale (C.UTF-8)
10.244.0.1 - - [27/Feb/2019 15:25:18] "PUT /api/rules HTTP/1.1" 200 -
```

```shell
[root@hypervisor ~]# iptables -L -n -t mangle
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
TEE        all  --  10.200.0.11          0.0.0.0/0            TEE gw:10.200.0.103

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
 ```

```shell
[root@hypervisor ~]# ping -I 10.200.0.11 10.200.0.1
PING 10.200.0.1 (10.200.0.1) from 10.200.0.11 : 56(84) bytes of data.
64 bytes from 10.200.0.1: icmp_seq=1 ttl=64 time=0.042 ms
64 bytes from 10.200.0.1: icmp_seq=2 ttl=64 time=0.043 ms
64 bytes from 10.200.0.1: icmp_seq=3 ttl=64 time=0.029 ms
64 bytes from 10.200.0.1: icmp_seq=4 ttl=64 time=0.027 ms
64 bytes from 10.200.0.1: icmp_seq=5 ttl=64 time=0.046 ms
^C
--- 10.200.0.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 3999ms
rtt min/avg/max/mdev = 0.027/0.037/0.046/0.009 ms
```

```shell
[root@master rp2]# kubectl cp surf-vnf-tcpdump-8d5fff4b6-b8qvd:/surf/vnf-tcpdump-log.pcap vnf-tcpdump-log.pcap
```


## OBSERVATION WHEN NOT USING KATA BUT RUNC:
```shell
[root@master rp2]# kubectl get pods -o wide                                                                                                                                                    
NAME                                   READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE
rqlite-leader-5bd7f85775-pjf62         1/1     Running   0          3m58s   10.244.1.12    slave    <none>
rqlite-node-67488b8964-lk7pd           1/1     Running   0          3m37s   10.244.1.13    slave    <none>
rqlite-node-67488b8964-sxbxg           1/1     Running   1          3m37s   10.244.0.192   master   <none>
surf-nfv-controller-7894968775-g5tdc   1/1     Running   0          3m17s   10.244.1.14    slave    <none>
surf-nfv-controller-7894968775-tcrkt   1/1     Running   0          3m17s   10.244.0.193   master   <none>
surf-vnf-tcpdump-778ff56576-mtxl4      1/1     Running   0          2m53s   10.244.1.15    slave    <none>
```

```shell
[root@hypervisor ~]# ping -I 10.200.0.11 10.200.0.1
PING 10.200.0.1 (10.200.0.1) from 10.200.0.11 : 56(84) bytes of data.
64 bytes from 10.200.0.1: icmp_seq=1 ttl=64 time=0.042 ms
64 bytes from 10.200.0.1: icmp_seq=2 ttl=64 time=0.048 ms
From 10.200.0.104 icmp_seq=2 Redirect Host(New nexthop: 10.200.0.1)
From 10.200.0.104: icmp_seq=2 Redirect Host(New nexthop: 10.200.0.1)
64 bytes from 10.200.0.1: icmp_seq=3 ttl=64 time=0.033 ms
From 10.200.0.104 icmp_seq=3 Redirect Host(New nexthop: 10.200.0.1)
From 10.200.0.104: icmp_seq=3 Redirect Host(New nexthop: 10.200.0.1)
64 bytes from 10.200.0.1: icmp_seq=4 ttl=64 time=0.030 ms
From 10.200.0.104 icmp_seq=4 Time to live exceeded
64 bytes from 10.200.0.1: icmp_seq=5 ttl=64 time=0.044 ms
From 10.200.0.104 icmp_seq=5 Time to live exceeded
64 bytes from 10.200.0.1: icmp_seq=6 ttl=64 time=0.032 ms
From 10.200.0.104 icmp_seq=6 Time to live exceeded
64 bytes from 10.200.0.1: icmp_seq=7 ttl=64 time=0.030 ms
64 bytes from 10.200.0.1: icmp_seq=8 ttl=64 time=0.061 ms
64 bytes from 10.200.0.1: icmp_seq=9 ttl=64 time=0.076 ms
64 bytes from 10.200.0.1: icmp_seq=10 ttl=64 time=0.039 ms
64 bytes from 10.200.0.1: icmp_seq=11 ttl=64 time=0.049 ms
64 bytes from 10.200.0.1: icmp_seq=12 ttl=64 time=0.058 ms
^C
--- 10.200.0.1 ping statistics ---
12 packets transmitted, 12 received, +5 errors, 0% packet loss, time 11003ms
rtt min/avg/max/mdev = 0.030/0.045/0.076/0.014 ms
```
