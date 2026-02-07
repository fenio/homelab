# Volume Adoption from democratic-csi to tns-csi

This directory contains adoption manifests for migrating volumes from democratic-csi to tns-csi.

## Adopted Volumes

| PVC Name | Namespace | Size | Protocol | Used By |
|----------|-----------|------|----------|---------|
| data-kyoo-rabbitmq-0 | media | 8Gi | iSCSI | kyoo-rabbitmq |
| data-kyoo-postgresql-0 | media | 3Gi | iSCSI | kyoo-postgresql |
| media | media | 1000Gi | NFS | dms, kyoo-scanner, kyoo-transcoder, qbittorrent |

## Migration Steps

**IMPORTANT:** This migration causes downtime. Perform during a maintenance window.

### Step 1: Scale down workloads

```bash
# Scale down media workloads using NFS
kubectl scale deployment -n media dms --replicas=0
kubectl scale deployment -n media kyoo-scanner --replicas=0
kubectl scale deployment -n media kyoo-transcoder --replicas=0
kubectl scale statefulset -n media qbittorrent --replicas=0

# Scale down kyoo services using iSCSI
kubectl scale statefulset -n media kyoo-rabbitmq --replicas=0
kubectl scale statefulset -n media kyoo-postgresql --replicas=0
```

### Step 2: Delete old PVCs (data is safe - PVs have Retain policy)

```bash
kubectl delete pvc -n media data-kyoo-rabbitmq-0 data-kyoo-postgresql-0 media
```

### Step 3: Delete old PVs

```bash
kubectl delete pv pv-pvc-ddaff1f7-1f7d-4e71-97ba-ea30b493921c
kubectl delete pv pv-pvc-f4ae9e8b-6023-41f3-ace0-e5e290c350b6
kubectl delete pv pv-pvc-fc1abc3a-dd41-4bfb-9f36-77763af19292
```

### Step 4: Apply new adoption manifests

```bash
kubectl apply -k /path/to/adoption/
```

### Step 5: Verify PVs and PVCs are Bound

```bash
kubectl get pv | grep pvc-
kubectl get pvc -n media data-kyoo-rabbitmq-0 data-kyoo-postgresql-0 media
```

### Step 6: Scale up workloads

```bash
kubectl scale deployment -n media dms --replicas=1
kubectl scale deployment -n media kyoo-scanner --replicas=1
kubectl scale deployment -n media kyoo-transcoder --replicas=1
kubectl scale statefulset -n media qbittorrent --replicas=1
kubectl scale statefulset -n media kyoo-rabbitmq --replicas=1
kubectl scale statefulset -n media kyoo-postgresql --replicas=1
```

## Rollback

If something goes wrong, the data is safe on TrueNAS. To rollback:

1. Delete the new PVs/PVCs
2. Re-create the old PVs/PVCs with `pv-pvc-` naming
3. Scale up workloads
