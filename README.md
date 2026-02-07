# Talos-based homelab powered by Flux

<details open>
<summary><h2 style="display: inline-block; margin: 0;">Overview</h2></summary>

This is home to my personal Kubernetes lab cluster running on [Talos Linux](https://www.talos.dev/) and managed by [Sidero Omni](https://omni.siderolabs.com/). [Flux](https://github.com/fluxcd/flux2) watches this Git repository and makes the changes to my cluster based on the manifests in the [cluster](./cluster/) directory. [Renovate](https://github.com/renovatebot/renovate) also watches this Git repository and creates pull requests when it finds updates to Docker images, Helm charts, and other dependencies.

</details>

<details>
<summary><h2 style="display: inline-block; margin: 0;">Hardware</h2></summary>

![lab](https://github.com/fenio/dumb-provisioner/blob/main/IMG_0891.jpeg)

| Device                        | Count | OS Disk Size | Data Disk Size | Ram  | Operating System | Purpose           |
| ----------------------------- | ----- | ------------ | -------------- | ---- | ---------------- | ----------------- |
| Mikrotik RB4011iGS+5HacQ2HnD | 1     | 512MB        |                | 1GB  | RouterOS 7.13    | Router            |
| Dell Wyse 5070                | 3     | 16GB         | 128GB          | 12GB | Talos v1.12.2    | Control plane     |
| Odroid H3+                    | 1     | 64GB         | 8x480GB SSD    | 32GB | TrueNAS Scale    | NAS / storage     |

</details>

<details>
<summary><h2 style="display: inline-block; margin: 0;">Cluster architecture</h2></summary>

- **OS**: Talos Linux v1.12.2 (managed via Sidero Omni)
- **Kubernetes**: v1.35.0
- **CNI**: Cilium v1.19.0 (kube-proxy replacement, Wireguard encryption, BGP control plane)
- **GitOps**: Flux v2.7.3 (installed via flux-operator)
- **Secrets**: SOPS with AGE encryption
- **Storage**: tns-csi (NFS, iSCSI, NVMe-oF) backed by TrueNAS
- **Monitoring**: VictoriaMetrics, Grafana, Coroot, Hubble

### Network layout

| Subnet        | Purpose         |
| ------------- | --------------- |
| 10.10.20.97   | Gateway         |
| 10.10.20.100  | TrueNAS         |
| 10.10.20.101  | node1 (enp1s0)  |
| 10.10.20.102  | node2 (enp1s0)  |
| 10.10.20.103  | node3 (enp3s0)  |
| 10.20.0.0/16  | Pod CIDR        |

</details>

## Installing the cluster from scratch

### Prerequisites

Install the following tools on your workstation:

- [omnictl](https://omni.siderolabs.com/docs/reference/cli/) - Sidero Omni CLI
- [helmfile](https://github.com/helmfile/helmfile) - declarative Helm chart management
- [helm](https://helm.sh/) - Kubernetes package manager
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [sops](https://github.com/getsops/sops) - secrets encryption
- [age](https://github.com/FiloSottile/age) - encryption tool used by SOPS
- [task](https://taskfile.dev/) - task runner (optional, for automation)

### Step 1: Prepare Talos ISO

Download a custom Talos ISO with required extensions:

```sh
omnictl download iso \
  --arch amd64 \
  --secureboot \
  --extensions amdgpu,amd-ucode,i915,intel-ice-firmware,intel-ucode,iscsi-tools,realtek-firmware \
  --extra-kernel-args -lockdown,lockdown=integrity,mitigations=off \
  --output /tmp/talos.iso
```

Boot all three nodes from this ISO. They will register with Omni automatically.

### Step 2: Apply cluster template via Omni

The cluster is defined in [`talos/homelab.yaml`](./talos/homelab.yaml). This template configures:
- 3-node control plane (no dedicated workers, scheduling on control planes enabled)
- No built-in CNI (Cilium installed separately)
- kube-proxy disabled (Cilium replaces it)
- Static IPs for each node

```sh
omnictl cluster template sync -f talos/homelab.yaml
```

Wait for all nodes to join and become ready in Omni.

### Step 3: Get kubeconfig

```sh
omnictl kubeconfig -c homelab
```

Verify the nodes are ready:

```sh
kubectl get nodes
NAME    STATUS     ROLES           AGE   VERSION
node1   NotReady   control-plane   1m    v1.35.0
node2   NotReady   control-plane   1m    v1.35.0
node3   NotReady   control-plane   1m    v1.35.0
```

Nodes will be `NotReady` until Cilium is installed.

### Step 4: Install base components with helmfile

[`helmfile`](./talos/helmfile.yaml) installs components in order:

1. **prometheus-operator-crds** - CRDs needed by ServiceMonitors
2. **cilium** - CNI with kube-proxy replacement, Wireguard, Hubble
3. **flux-operator** - Flux lifecycle manager
4. **flux-instance** - Flux deployment pointing to this Git repository

```sh
helmfile --file talos/helmfile.yaml apply --skip-diff-on-install --suppress-diff
```

This will take a few minutes. After completion, nodes should become `Ready`:

```sh
kubectl get nodes
NAME    STATUS   ROLES           AGE   VERSION
node1   Ready    control-plane   5m    v1.35.0
node2   Ready    control-plane   5m    v1.35.0
node3   Ready    control-plane   5m    v1.35.0
```

Verify Cilium is healthy:

```sh
cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       OK
    \__/       ClusterMesh:        disabled
```

### Step 5: Bootstrap Flux secrets

Flux is now running but needs secrets to decrypt SOPS-encrypted values and access the Git repository.

**Make sure your AGE key file is available:**

```sh
export SOPS_AGE_KEY_FILE=~/AGE/sops-key.txt
```

**Apply the SOPS decryption key:**

```sh
kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=$SOPS_AGE_KEY_FILE
```

**Apply cluster secrets and settings:**

```sh
sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f cluster/flux/vars/cluster-settings.yaml
```

### Step 6: Wait for Flux to reconcile

Flux will now start reconciling all resources from this repository. Monitor progress:

```sh
flux get kustomization
```

All kustomizations should eventually show `Ready: True`. The dependency chain ensures components are installed in the correct order (tns-csi -> databases -> applications).

### Automated alternative

If you have [task](https://taskfile.dev/) installed, steps 1-4 can be run with a single command from the repo root:

```sh
task bootstrap
```

This runs: download-iso -> template-sync -> kubeconfig -> helmfile-apply

Step 5 (Flux secrets) can also be automated:

```sh
export SOPS_AGE_KEY_FILE=~/AGE/sops-key.txt
task flux:bootstrap
```

## AGE / SOPS secrets

Generate a new AGE key (only needed once):

```sh
age-keygen -o sops-key.txt
```

Encrypt/decrypt the cluster secrets file:

```sh
# Decrypt (to edit)
sops cluster/flux/vars/cluster-secrets.sops.yaml

# The .sops.yaml file at the repo root defines encryption rules
```
