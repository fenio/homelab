# TNS CSI Driver Integration Setup Guide

This document guides you through integrating the TNS CSI driver into your homelab Kubernetes cluster.

## Files Created

The following files have been created in your homelab repository:

1. **Git Repository**: `cluster/flux/repositories/git/tns-csi.yaml`
   - Adds the TNS CSI repository from GitHub to Flux

2. **TNS CSI Application**:
   - `cluster/apps/disk/tns-csi/app/helmrelease.yaml` - Helm release with values
   - `cluster/apps/disk/tns-csi/app/kustomization.yaml` - Kustomization for the app
   - `cluster/apps/disk/tns-csi/ks.yaml` - Flux Kustomization for deployment

3. **Updated**: `cluster/apps/disk/kustomization.yaml`
   - Added reference to tns-csi

## Step 1: Update Cluster Settings

Edit `cluster/flux/vars/cluster-settings.yaml` and add your TrueNAS configuration:

```yaml
CONFIG_TRUENAS_IP: "10.10.20.100"  # Replace with your TrueNAS IP
```

## Step 2: Create TrueNAS Credentials Secret

You need to create a Kubernetes secret with TrueNAS API credentials. This should be encrypted with SOPS.

### Generate the Secret

First, create an unencrypted secret file:

```bash
cat > /tmp/tns-csi-secret.yaml <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: tns-csi-credentials
  namespace: kube-system
type: Opaque
stringData:
  url: "wss://10.10.20.100:443/api/current"
  api-key: "your-truenas-api-key"
EOF
```

Replace:
- `10.10.20.100` with your TrueNAS IP
- `your-truenas-api-key` with your actual API key (generate in TrueNAS UI: System > API Keys)

### Encrypt with SOPS

```bash
sops --encrypt /tmp/tns-csi-secret.yaml > cluster/apps/disk/tns-csi/secret.sops.yaml
```

### Update the Kustomization

Add the encrypted secret to `cluster/apps/disk/tns-csi/app/kustomization.yaml`:

```yaml
resources:
  - helmrelease.yaml
  - ../secret.sops.yaml
configMapGenerator:
  - name: tns-csi-values
    files:
      - values.yaml=values.yaml
```

## Step 3: Update Values Configuration

Edit `cluster/apps/disk/tns-csi/app/values.yaml` with your specific setup:

```yaml
storageClasses:
  nfs:
    pool: "storage"  # Your TrueNAS pool name
    server: "10.10.20.100"  # Your TrueNAS IP
    isDefault: true  # Set as default storage class
```

## Step 4: Git Repository Configuration

The Git repository is already configured in `cluster/flux/repositories/git/tns-csi.yaml` and included in `cluster/flux/repositories/git/kustomization.yaml`. Flux will automatically:

1. Clone the TNS CSI repository from GitHub
2. Track changes on the `main` branch
3. Check for updates every 10 minutes
4. Deploy the Helm chart from `charts/tns-csi-driver`

No additional configuration is needed.

## Step 5: Deploy via Flux

Once you've made the changes above and pushed to your Git repository, Flux will automatically deploy the TNS CSI driver. You can monitor the deployment with:

```bash
kubectl get helmrelease -n kube-system tns-csi -w
kubectl describe helmrelease -n kube-system tns-csi
```

## Step 6: Verify Installation

Check if the CSI driver is installed:

```bash
kubectl get csidriver
```

Check if the storage class was created:

```bash
kubectl get storageclass
```

Verify the controller and node pods are running:

```bash
kubectl get pods -n kube-system | grep tns-csi
```

## Troubleshooting

### HelmRelease is stuck in "Not Ready" state

Check the controller pod logs:

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=tns-csi-driver -l app.kubernetes.io/component=controller
```

### Secret not found error

Make sure the encrypted secret exists at `cluster/apps/disk/tns-csi/secret.sops.yaml` and that SOPS is configured correctly.

### TrueNAS connection issues

1. Verify TrueNAS is accessible from the cluster
2. Check API key is correct (generate a new one if needed)
3. Ensure the WebSocket URL format is correct: `wss://ip:port/api/current`

## Storage Class Usage

Once deployed, you can create PVCs using the TNS CSI driver:

### NFS Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-nfs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: tns-csi-nfs
  resources:
    requests:
      storage: 10Gi
```

### Enabling NVMe-oF

To use NVMe-oF instead of NFS, edit `cluster/apps/disk/tns-csi/app/values.yaml`:

```yaml
storageClasses:
  nfs:
    enabled: false
  nvmeof:
    enabled: true
    isDefault: true
    pool: "storage"
    server: "10.10.20.100"
```

**Note**: NVMe-oF requires:
- Linux kernel with nvme-tcp module support
- TrueNAS NVMe-oF target configured
- Corresponding iSCSI portal settings on TrueNAS

## References

- [TNS CSI Driver Repository](https://github.com/fenio/tns-csi)
- [TNS CSI Helm Chart](https://github.com/fenio/tns-csi/tree/main/charts/tns-csi-driver)
- [Kubernetes CSI Documentation](https://kubernetes.io/docs/concepts/storage/volumes/#csi)
