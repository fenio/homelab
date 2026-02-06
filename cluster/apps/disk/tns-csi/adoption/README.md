# Volume Adoption from democratic-csi to tns-csi

This directory contains adoption manifests for migrating volumes from democratic-csi to tns-csi.

## Volumes to Migrate

| PVC Name | Namespace | Size | Protocol | Used By |
|----------|-----------|------|----------|---------|
| postgres-2 | db | 50Gi | iSCSI | postgres-2 pod |
| postgres-4 | db | 50Gi | iSCSI | postgres-4 pod |
| postgres-5 | db | 50Gi | iSCSI | postgres-5 pod |
| data-kyoo-rabbitmq-0 | media | 8Gi | iSCSI | kyoo-rabbitmq |
| data-kyoo-postgresql-0 | media | 3Gi | iSCSI | kyoo-postgresql |
| media | media | 1000Gi | NFS | dms, kyoo-scanner, kyoo-transcoder, qbittorrent |

## Prerequisites

The datasets have already been imported into tns-csi management:
```bash
kubectl tns-csi import storage/iscsi/v/pvc-xxx --protocol iscsi --secret kube-system/tns-csi-credentials
kubectl tns-csi import storage/nfs/v/pvc-xxx --protocol nfs --secret kube-system/tns-csi-credentials
```

## Migration Steps

**IMPORTANT:** This migration causes downtime. Perform during a maintenance window.

### Step 1: Protect existing PVs (set Retain policy)

```bash
# Protect all democratic-csi PVs from deletion
kubectl patch pv pvc-8939fd63-235a-4715-8de6-bb11c7063a77 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-b6568a4d-7890-4017-9921-118d374f5879 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-3d859503-1724-4ace-b5ff-a09834b14327 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-ddaff1f7-1f7d-4e71-97ba-ea30b493921c -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-f4ae9e8b-6023-41f3-ace0-e5e290c350b6 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-fc1abc3a-dd41-4bfb-9f36-77763af19292 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

### Step 2: Scale down workloads

```bash
# Scale down PostgreSQL (if using cloudnative-pg, scale the cluster)
# Check what manages these pods first
kubectl get pods -n db postgres-2 postgres-4 postgres-5 -o jsonpath='{.items[*].metadata.ownerReferences[*].kind}'

# Scale down media workloads using NFS
kubectl scale deployment -n media dms --replicas=0
kubectl scale deployment -n media kyoo-scanner --replicas=0
kubectl scale deployment -n media kyoo-transcoder --replicas=0
kubectl scale statefulset -n media qbittorrent --replicas=0

# Scale down kyoo services using iSCSI (if running)
# kubectl scale statefulset -n media kyoo-rabbitmq --replicas=0
# kubectl scale statefulset -n media kyoo-postgresql --replicas=0
```

### Step 3: Delete old PVCs (data is safe - PVs have Retain policy)

```bash
# Delete db namespace PVCs
kubectl delete pvc -n db postgres-2 postgres-4 postgres-5

# Delete media namespace PVCs
kubectl delete pvc -n media data-kyoo-rabbitmq-0 data-kyoo-postgresql-0 media
```

### Step 4: Delete old PVs

```bash
kubectl delete pv pvc-8939fd63-235a-4715-8de6-bb11c7063a77
kubectl delete pv pvc-b6568a4d-7890-4017-9921-118d374f5879
kubectl delete pv pvc-3d859503-1724-4ace-b5ff-a09834b14327
kubectl delete pv pvc-ddaff1f7-1f7d-4e71-97ba-ea30b493921c
kubectl delete pv pvc-f4ae9e8b-6023-41f3-ace0-e5e290c350b6
kubectl delete pv pvc-fc1abc3a-dd41-4bfb-9f36-77763af19292
```

### Step 5: Apply new adoption manifests

```bash
# Apply all adoption manifests
kubectl apply -k /path/to/adoption/

# Or apply individually:
kubectl apply -f db-postgres.yaml
kubectl apply -f media-kyoo.yaml
kubectl apply -f media-nfs.yaml
```

### Step 6: Verify PVs and PVCs are Bound

```bash
kubectl get pv | grep pv-pvc-
kubectl get pvc -n db postgres-2 postgres-4 postgres-5
kubectl get pvc -n media data-kyoo-rabbitmq-0 data-kyoo-postgresql-0 media
```

### Step 7: Scale up workloads

```bash
# Scale up media workloads
kubectl scale deployment -n media dms --replicas=1
kubectl scale deployment -n media kyoo-scanner --replicas=1
kubectl scale deployment -n media kyoo-transcoder --replicas=1
kubectl scale statefulset -n media qbittorrent --replicas=1

# Scale up kyoo services (if using them)
# kubectl scale statefulset -n media kyoo-rabbitmq --replicas=1
# kubectl scale statefulset -n media kyoo-postgresql --replicas=1

# PostgreSQL - restart per your setup (cloudnative-pg will auto-recover)
```

### Step 8: Verify workloads are running

```bash
kubectl get pods -n db
kubectl get pods -n media
```

## Rollback

If something goes wrong, the data is safe on TrueNAS. To rollback:

1. Delete the new PVs/PVCs
2. Re-create the old democratic-csi PVs/PVCs manually or let democratic-csi provision them
3. Scale up workloads

## Post-Migration

After successful migration, you can:
1. Remove democratic-csi from the cluster (optional)
2. Update StorageClasses to use tns-csi as default
3. Commit these manifests to GitOps for disaster recovery
