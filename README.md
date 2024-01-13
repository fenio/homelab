# k0s based homelab powered by flux

<details open>
<summary><h2 style="display: inline-block; margin: 0;">📖 Overview</h2></summary>

This is home to my personal Kubernetes lab cluster. [Flux](https://github.com/fluxcd/flux2) watches this Git repository and makes the changes to my cluster based on the manifests in the [cluster](./cluster/) directory.
[Renovate](https://github.com/renovatebot/renovate) also watches this Git repository and creates pull requests when it finds updates to Docker images, Helm charts, and other dependencies.

The whole setup is heavily based on [onedr0p's template](https://github.com/onedr0p/flux-cluster-template) but I didn't really want to use his ansible machinery for HW provisioning and k8s install so I grabbed just some stuff from him and I tackled these parts on my way.

So for HW provisioning go to [HW section](https://github.com/fenio/homelab#hardware-provisioning)

And for k8s install go to [install section](https://github.com/fenio/homelab#kubernetes-installation-using-k0sctl)

And if you have working k8s cluster and you just want to start using Flux to deploy workloads on it then simply move to [Flux](https://github.com/fenio/homelab#flux) section.

</details>

<details>
  <summary><h2 style="display: inline-block; margin: 0;">Hardware provisioning</h2></summary>

Few words about my HW setup. Here's a picture of it:

![lab](https://github.com/fenio/dumb-provisioner/blob/main/IMG_0891.jpeg)

NAS runs TrueNAS Scale and it's installed manually as I don't expect it to be reinstalled too often.
K8S related stuff like Dell Wyse terminals and master node which is running on NAS as a VM are being reinstalled from time to time so I had to figure out some way to do it easily.
That's how [dumb provisioner](https://github.com/fenio/dumb-provisioner/) was born.

## 🔧 Hardware

| Device                       | Count | OS Disk Size   | Data Disk Size     | Ram  | Operating System      | Purpose                      |
| ---------------------------- | ----- | -------------- | ------------------ | ---- | --------------------- | ---------------------------- |
| Mikrotik RB4011iGS+5HacQ2HnD | 1     | 512MB          |                    | 1GB  | RouterOS 7.13         | router                       |
| Dell Wyse 5070               | 3     | 16GB           | 128GB              | 12GB | Debian 12.4           | node(s)                      |
| Odroid H3+                   | 1     | 64GB           | 8x480GB SSD        | 32GB | TrueNAS Scale 23.10.1 | k8s storage / master (in vm) |

</details>

<details>
  <summary><h2 style="display: inline-block; margin: 0;">Kubernetes installation using k0s(ctl)</h2></summary>

k0sctl allows to **greatly** simplify k8s install. Below is my configuration file which basically allows me to install whole cluster within minutes.
Obviously every host which is later part of the cluster needs to be accessible via SSH.


```sh
❯ ~/homelab cat k0sctl.yaml
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: lab
spec:
  hosts:
  - ssh:
      address: 10.10.20.99
      user: root
      port: 22
      keyPath: ~/.ssh/id_rsa
    role: controller
    files:
    - name: Prometheus CRDs
      src: prometheus-crds.yaml
      dstDir: /var/lib/k0s/manifests/prometheus/
      perm: 0600
    installFlags:
    - --disable-components=metrics-server
    - --enable-metrics-scraper
  - ssh:
      address: 10.10.20.101
      user: root
      port: 22
      keyPath: ~/.ssh/id_rsa
    role: worker
  - ssh:
      address: 10.10.20.102
      user: root
      port: 22
      keyPath: ~/.ssh/id_rsa
    role: worker
  - ssh:
      address: 10.10.20.103
      user: root
      port: 22
      keyPath: ~/.ssh/id_rsa
    role: worker
  k0s:
    version: 1.28.5+k0s.0
    dynamicConfig: false
    config:
      spec:
        network:
          provider: custom
          kubeProxy:
            disabled: true
        extensions:
          helm:
            repositories:
            - name: cilium
              url: https://helm.cilium.io
            charts:
            - name: cilium
              chartname: cilium/cilium
              version: "1.14.5"
              namespace: kube-system
              values: |2
                bgpControlPlane:
                  enabled: true
                bgp:
                  enabled: false
                kubeProxyReplacement: true
                k8sServiceHost: 10.10.20.99
                k8sServicePort: 6443
                encryption:
                  enabled: true
                  type: wireguard
                  nodeEncryption: true
                operator:
                  replicas: 1
                  prometheus:
                    enabled: true
                    serviceMonitor:
                      enabled: true
                ipam:
                  mode: kubernetes
                  operator:
                    clusterPoolIPv4PodCIDR: 10.20.0.0/16
                    clusterPoolIPv4MaskSize: 24
                bpf:
                  masquerade: true
                prometheus:
                  enabled: true
                  serviceMonitor:
                    enabled: true
```

Once you've got such configuration you just have to run the following command:

```sh
❯ ~/homelab k0sctl apply --config k0sctl.yaml

⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████
k0sctl v0.17.4 Copyright 2023, k0sctl authors.
Anonymized telemetry of usage will be sent to the authors.
By continuing to use k0sctl you agree to these terms:
https://k0sproject.io/licenses/eula
INFO ==> Running phase: Connect to hosts
INFO [ssh] 10.10.20.99:22: connected
INFO [ssh] 10.10.20.102:22: connected
INFO [ssh] 10.10.20.103:22: connected
INFO [ssh] 10.10.20.101:22: connected
INFO ==> Running phase: Detect host operating systems
INFO [ssh] 10.10.20.103:22: is running Debian GNU/Linux 12 (bookworm)
INFO [ssh] 10.10.20.99:22: is running Debian GNU/Linux 12 (bookworm)
INFO [ssh] 10.10.20.101:22: is running Debian GNU/Linux 12 (bookworm)
INFO [ssh] 10.10.20.102:22: is running Debian GNU/Linux 12 (bookworm)
INFO ==> Running phase: Acquire exclusive host lock
INFO ==> Running phase: Prepare hosts
INFO [ssh] 10.10.20.99:22: installing package curl
INFO ==> Running phase: Gather host facts
INFO [ssh] 10.10.20.102:22: using node2 as hostname
INFO [ssh] 10.10.20.103:22: using node3 as hostname
INFO [ssh] 10.10.20.101:22: using node1 as hostname
INFO [ssh] 10.10.20.99:22: using master as hostname
INFO [ssh] 10.10.20.103:22: discovered enp1s0 as private interface
INFO [ssh] 10.10.20.102:22: discovered enp1s0 as private interface
INFO [ssh] 10.10.20.101:22: discovered enp1s0 as private interface
INFO [ssh] 10.10.20.99:22: discovered ens3 as private interface
INFO ==> Running phase: Validate hosts
INFO ==> Running phase: Validate facts
INFO ==> Running phase: Download k0s on hosts
INFO [ssh] 10.10.20.103:22: downloading k0s v1.28.5+k0s.0
INFO [ssh] 10.10.20.101:22: downloading k0s v1.28.5+k0s.0
INFO [ssh] 10.10.20.102:22: downloading k0s v1.28.5+k0s.0
INFO [ssh] 10.10.20.99:22: downloading k0s v1.28.5+k0s.0
INFO ==> Running phase: Upload files to hosts
INFO [ssh] 10.10.20.99:22: uploading Prometheus CRDs
INFO ==> Running phase: Install k0s binaries on hosts
INFO [ssh] 10.10.20.99:22: validating configuration
INFO ==> Running phase: Configure k0s
INFO [ssh] 10.10.20.99:22: installing new configuration
INFO ==> Running phase: Initialize the k0s cluster
INFO [ssh] 10.10.20.99:22: installing k0s controller
INFO [ssh] 10.10.20.99:22: waiting for the k0s service to start
INFO [ssh] 10.10.20.99:22: waiting for kubernetes api to respond
INFO ==> Running phase: Install workers
INFO [ssh] 10.10.20.103:22: validating api connection to https://10.10.20.99:6443
INFO [ssh] 10.10.20.101:22: validating api connection to https://10.10.20.99:6443
INFO [ssh] 10.10.20.102:22: validating api connection to https://10.10.20.99:6443
INFO [ssh] 10.10.20.99:22: generating a join token for worker 1
INFO [ssh] 10.10.20.99:22: generating a join token for worker 2
INFO [ssh] 10.10.20.99:22: generating a join token for worker 3
INFO [ssh] 10.10.20.101:22: writing join token
INFO [ssh] 10.10.20.102:22: writing join token
INFO [ssh] 10.10.20.103:22: writing join token
INFO [ssh] 10.10.20.101:22: installing k0s worker
INFO [ssh] 10.10.20.102:22: installing k0s worker
INFO [ssh] 10.10.20.103:22: installing k0s worker
INFO [ssh] 10.10.20.102:22: starting service
INFO [ssh] 10.10.20.103:22: starting service
INFO [ssh] 10.10.20.101:22: starting service
INFO [ssh] 10.10.20.103:22: waiting for node to become ready
INFO [ssh] 10.10.20.101:22: waiting for node to become ready
INFO [ssh] 10.10.20.102:22: waiting for node to become ready
INFO ==> Running phase: Release exclusive host lock
INFO ==> Running phase: Disconnect from hosts
INFO ==> Finished in 1m42s
INFO k0s cluster version v1.28.5+k0s.0 is now installed
INFO Tip: To access the cluster you can now fetch the admin kubeconfig using:
INFO      k0sctl kubeconfig
```

And after less than 2 minutes you should end up with working cluster with Cilium as a CNI:

```sh
❯ ~ k0sctl kubeconfig > ~/.kube/config

[☸ lab:default]
❯ ~ kubectl get nodes
NAME    STATUS   ROLES    AGE     VERSION
node1   Ready    <none>   2m10s   v1.28.5+k0s
node2   Ready    <none>   2m16s   v1.28.5+k0s
node3   Ready    <none>   2m16s   v1.28.5+k0s

[☸ lab:default]
❯ ~ cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

Deployment             cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
DaemonSet              cilium             Desired: 3, Ready: 3/3, Available: 3/3
Containers:            cilium             Running: 3
                       cilium-operator    Running: 1
Cluster Pods:          6/6 managed by Cilium
Helm chart version:    1.14.5
Image versions         cilium             quay.io/cilium/cilium:v1.14.5@sha256:d3b287029755b6a47dee01420e2ea469469f1b174a2089c10af7e5e9289ef05b: 3
                       cilium-operator    quay.io/cilium/operator-generic:v1.14.5@sha256:303f9076bdc73b3fc32aaedee64a14f6f44c8bb08ee9e3956d443021103ebe7a: 1
```

We can get more info about CNI status by running `cilium status` from inside of one of its POD:

```
[☸ lab:kube-system]
❯ ~ kubectl exec -it cilium-25r4n -- /bin/sh
Defaulted container "cilium-agent" out of: cilium-agent, config (init), mount-cgroup (init), apply-sysctl-overwrites (init), mount-bpf-fs (init), clean-cilium-state (init), install-cni-binaries (init)
# cilium status
KVStore:                 Ok   Disabled
Kubernetes:              Ok   1.28 (v1.28.5+k0s) [linux/amd64]
Kubernetes APIs:         ["EndpointSliceOrEndpoint", "cilium/v2::CiliumClusterwideNetworkPolicy", "cilium/v2::CiliumEndpoint", "cilium/v2::CiliumNetworkPolicy", "cilium/v2::CiliumNode", "cilium/v2alpha1::CiliumCIDRGroup", "core/v1::Namespace", "core/v1::Pods", "core/v1::Service", "networking.k8s.io/v1::NetworkPolicy"]
KubeProxyReplacement:    True   [enp1s0 10.10.20.101 (Direct Routing), cilium_wg0 ]
Host firewall:           Disabled
CNI Chaining:            none
Cilium:                  Ok   1.14.5 (v1.14.5-85db28be)
NodeMonitor:             Listening for events on 4 CPUs with 64x4096 of shared memory
Cilium health daemon:    Ok
IPAM:                    IPv4: 4/254 allocated from 10.244.1.0/24,
IPv4 BIG TCP:            Disabled
IPv6 BIG TCP:            Disabled
BandwidthManager:        Disabled
Host Routing:            BPF
Masquerading:            BPF   [enp1s0, cilium_wg0]   10.244.1.0/24 [IPv4: Enabled, IPv6: Disabled]
Controller Status:       30/30 healthy
Proxy Status:            OK, ip 10.244.1.49, 0 redirects active on ports 10000-20000, Envoy: embedded
Global Identity Range:   min 256, max 65535
Hubble:                  Ok              Current/Max Flows: 2479/4095 (60.54%), Flows/s: 9.27   Metrics: Disabled
Encryption:              Wireguard       [NodeEncryption: Enabled, cilium_wg0 (Pubkey: JrpKhZJ//XKclrd+6p8SGfp0GadsW7Ikxu7YWQK0hTk=, Port: 51871, Peers: 2)]
Cluster health:          3/3 reachable   (2024-01-12T05:26:31Z)
```

As you can see we're in BPF mode with Wireguard enabled.

</details>

## Flux

### Install Flux

```sh
[☸ lab:default]
❯ ~/homelab $ kubectl apply --server-side --kustomize ./cluster/bootstrap/flux
namespace/flux-system serverside-applied
resourcequota/critical-pods serverside-applied
customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/buckets.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gitrepositories.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/helmcharts.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/helmreleases.helm.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/helmrepositories.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/imagepolicies.image.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/imagerepositories.image.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/imageupdateautomations.image.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/kustomizations.kustomize.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/ocirepositories.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/providers.notification.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/receivers.notification.toolkit.fluxcd.io serverside-applied
serviceaccount/helm-controller serverside-applied
serviceaccount/image-automation-controller serverside-applied
serviceaccount/image-reflector-controller serverside-applied
serviceaccount/kustomize-controller serverside-applied
serviceaccount/notification-controller serverside-applied
serviceaccount/source-controller serverside-applied
clusterrole.rbac.authorization.k8s.io/crd-controller serverside-applied
clusterrole.rbac.authorization.k8s.io/flux-edit serverside-applied
clusterrole.rbac.authorization.k8s.io/flux-view serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/cluster-reconciler serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/crd-controller serverside-applied
service/notification-controller serverside-applied
service/source-controller serverside-applied
service/webhook-receiver serverside-applied
deployment.apps/helm-controller serverside-applied
deployment.apps/image-automation-controller serverside-applied
deployment.apps/image-reflector-controller serverside-applied
deployment.apps/kustomize-controller serverside-applied
deployment.apps/notification-controller serverside-applied
deployment.apps/source-controller serverside-applied
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

**Make sure you've got SOPS configured so it can easily use your key file or point it to the correct file with something like this:**

```sh
export SOPS_AGE_KEY_FILE=~/AGE/sops-key.txt
```

```sh
[☸ lab:default]
❯ ~/homelab $ sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
secret/cluster-secrets created
secret/dns-credentials created
secret/pg-credentials created
secret/sops-age created
secret/github-deploy-key created

[☸ lab:default]
❯ ~/homelab $ kubectl apply -f cluster/flux/vars/cluster-settings.yaml
configmap/cluster-settings created
```
### Kick off Flux applying this repository

```sh
[☸ lab:default]
❯ ~/homelab $ kubectl apply --server-side --kustomize ./cluster/flux/config
kustomization.kustomize.toolkit.fluxcd.io/cluster serverside-applied
kustomization.kustomize.toolkit.fluxcd.io/flux serverside-applied
gitrepository.source.toolkit.fluxcd.io/homelab serverside-applied
ocirepository.source.toolkit.fluxcd.io/flux-manifests serverside-applied
```

All of the above in one shot using init.sh:

```sh
[☸ lab:default] [ main]
❯ ~/homelab ./init.sh
namespace/flux-system serverside-applied
resourcequota/critical-pods serverside-applied
customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/buckets.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gitrepositories.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/helmcharts.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/helmreleases.helm.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/helmrepositories.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/imagepolicies.image.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/imagerepositories.image.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/imageupdateautomations.image.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/kustomizations.kustomize.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/ocirepositories.source.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/providers.notification.toolkit.fluxcd.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/receivers.notification.toolkit.fluxcd.io serverside-applied
serviceaccount/helm-controller serverside-applied
serviceaccount/image-automation-controller serverside-applied
serviceaccount/image-reflector-controller serverside-applied
serviceaccount/kustomize-controller serverside-applied
serviceaccount/notification-controller serverside-applied
serviceaccount/source-controller serverside-applied
clusterrole.rbac.authorization.k8s.io/crd-controller serverside-applied
clusterrole.rbac.authorization.k8s.io/flux-edit serverside-applied
clusterrole.rbac.authorization.k8s.io/flux-view serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/cluster-reconciler serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/crd-controller serverside-applied
service/notification-controller serverside-applied
service/source-controller serverside-applied
service/webhook-receiver serverside-applied
deployment.apps/helm-controller serverside-applied
deployment.apps/image-automation-controller serverside-applied
deployment.apps/image-reflector-controller serverside-applied
deployment.apps/kustomize-controller serverside-applied
deployment.apps/notification-controller serverside-applied
deployment.apps/source-controller serverside-applied
secret/cluster-secrets created
secret/dns-credentials created
secret/pg-credentials created
secret/sops-age created
secret/github-deploy-key created
configmap/cluster-settings created
kustomization.kustomize.toolkit.fluxcd.io/cluster serverside-applied
kustomization.kustomize.toolkit.fluxcd.io/flux serverside-applied
gitrepository.source.toolkit.fluxcd.io/homelab serverside-applied
ocirepository.source.toolkit.fluxcd.io/flux-manifests serverside-applied
```

## AGE / SOPS secrets

```
[☸ lab:default]
❯ ~ $ age-keygen -o sops-key.txt
Public key: age1g8nxh9vntdtkjmsav07ytqetpuh2524a7e98f6a77rulu4rzvgwstyvhru

[☸ lab:default]
❯ ~ $ kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=sops-key.txt
secret/sops-age created

```
