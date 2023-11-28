# k0s based homelab powered by flux

<details open>
<summary><h2 style="display: inline-block; margin: 0;">📖 Overview</h2></summary>

This is home to my personal Kubernetes lab cluster. [Flux](https://github.com/fluxcd/flux2) watches this Git repository and makes the changes to my cluster based on the manifests in the [cluster](./cluster/) directory.
[Renovate](https://github.com/renovatebot/renovate) also watches this Git repository and creates pull requests when it finds updates to Docker images, Helm charts, and other dependencies.

</details>

<details>
  <summary><h2 style="display: inline-block; margin: 0;">Hardware provisioning</h2></summary>

![lab](https://github.com/fenio/dumb-provisioner/blob/main/IMG_0891.jpeg)

My assumption is that you've got few machines capable of being part of k8s cluster.
In my case 3 Wyse 5070 terminals and https://github.com/fenio/ugly-nas

</details>

<details>
  <summary>Kubernetes installation using k0s(ctl) (CLICK ME!)</summary>

k0sctl allow to **greatly** simplify k8s install. Belowe is my configuration file which basically allows me to install whole cluster within minutes.


```sh
❯ ~ cat k0sctl.yaml
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
    version: 1.28.4+k0s.0
    dynamicConfig: false
```

Once you've got such configuration you just have to run the following command:

```sh
❯ ~ k0sctl apply --config k0sctl.yaml

⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████
k0sctl v0.16.0 Copyright 2023, k0sctl authors.
Anonymized telemetry of usage will be sent to the authors.
By continuing to use k0sctl you agree to these terms:
https://k0sproject.io/licenses/eula
INFO ==> Running phase: Connect to hosts
INFO [ssh] 10.10.20.99:22: connected
INFO [ssh] 10.10.20.103:22: connected
INFO [ssh] 10.10.20.101:22: connected
INFO [ssh] 10.10.20.102:22: connected
INFO ==> Running phase: Detect host operating systems
INFO [ssh] 10.10.20.102:22: is running Debian GNU/Linux 12 (bookworm)
INFO [ssh] 10.10.20.99:22: is running Debian GNU/Linux 12 (bookworm)
INFO [ssh] 10.10.20.103:22: is running Debian GNU/Linux 12 (bookworm)
INFO [ssh] 10.10.20.101:22: is running Debian GNU/Linux 12 (bookworm)
INFO ==> Running phase: Acquire exclusive host lock
INFO ==> Running phase: Prepare hosts
INFO [ssh] 10.10.20.99:22: installing packages (curl)
INFO ==> Running phase: Gather host facts
INFO [ssh] 10.10.20.99:22: using master as hostname
INFO [ssh] 10.10.20.99:22: discovered ens3 as private interface
INFO [ssh] 10.10.20.103:22: using node3 as hostname
INFO [ssh] 10.10.20.102:22: using node2 as hostname
INFO [ssh] 10.10.20.101:22: using node1 as hostname
INFO [ssh] 10.10.20.101:22: discovered enp1s0 as private interface
INFO [ssh] 10.10.20.102:22: discovered enp1s0 as private interface
INFO [ssh] 10.10.20.103:22: discovered enp1s0 as private interface
INFO ==> Running phase: Validate hosts
INFO ==> Running phase: Gather k0s facts
INFO ==> Running phase: Validate facts
INFO ==> Running phase: Download k0s on hosts
INFO [ssh] 10.10.20.101:22: downloading k0s v1.28.4+k0s.0
INFO [ssh] 10.10.20.103:22: downloading k0s v1.28.4+k0s.0
INFO [ssh] 10.10.20.102:22: downloading k0s v1.28.4+k0s.0
INFO [ssh] 10.10.20.99:22: downloading k0s v1.28.4+k0s.0
INFO ==> Running phase: Install k0s binaries on hosts
INFO ==> Running phase: Configure k0s
WARN [ssh] 10.10.20.99:22: generating default configuration
INFO [ssh] 10.10.20.99:22: validating configuration
INFO [ssh] 10.10.20.99:22: configuration was changed, installing new configuration
INFO ==> Running phase: Initialize the k0s cluster
INFO [ssh] 10.10.20.99:22: installing k0s controller
INFO [ssh] 10.10.20.99:22: waiting for the k0s service to start
INFO [ssh] 10.10.20.99:22: waiting for kubernetes api to respond
INFO ==> Running phase: Install workers
INFO [ssh] 10.10.20.101:22: validating api connection to https://10.10.20.99:6443
INFO [ssh] 10.10.20.102:22: validating api connection to https://10.10.20.99:6443
INFO [ssh] 10.10.20.103:22: validating api connection to https://10.10.20.99:6443
INFO [ssh] 10.10.20.99:22: generating token
INFO [ssh] 10.10.20.101:22: writing join token
INFO [ssh] 10.10.20.102:22: writing join token
INFO [ssh] 10.10.20.103:22: writing join token
INFO [ssh] 10.10.20.102:22: installing k0s worker
INFO [ssh] 10.10.20.101:22: installing k0s worker
INFO [ssh] 10.10.20.103:22: installing k0s worker
INFO [ssh] 10.10.20.102:22: starting service
INFO [ssh] 10.10.20.101:22: starting service
INFO [ssh] 10.10.20.103:22: starting service
INFO [ssh] 10.10.20.102:22: waiting for node to become ready
INFO [ssh] 10.10.20.101:22: waiting for node to become ready
INFO [ssh] 10.10.20.103:22: waiting for node to become ready
INFO ==> Running phase: Release exclusive host lock
INFO ==> Running phase: Disconnect from hosts
INFO ==> Finished in 1m25s
INFO k0s cluster version v1.28.4+k0s.0 is now installed
```

And after 1m25s you should end up with working cluster:

```sh
[☸ lab:default]
❯ ~ kubectl get nodes
NAME    STATUS   ROLES    AGE     VERSION
node1   Ready    <none>   2d21h   v1.28.4+k0s
node2   Ready    <none>   2d21h   v1.28.4+k0s
node3   Ready    <none>   2d21h   v1.28.4+k0s
```
</details>

## Flux

### Install Flux

```sh
kubectl apply --server-side --kustomize ./cluster/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt cluster/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/bootstrap/flux/github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f cluster/flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```sh
kubectl apply --server-side --kustomize ./cluster/flux/config
```


## AGE / SOPS secrets

```
[☸ lab:default]
❯ ~ age-keygen -o sops-key.txt
Public key: age1g8nxh9vntdtkjmsav07ytqetpuh2524a7e98f6a77rulu4rzvgwstyvhru

[☸ lab:default]
❯ ~ kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=sops-key.txt
secret/sops-age created

```
