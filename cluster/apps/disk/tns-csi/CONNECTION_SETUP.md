# TNS CSI Driver - Connection Configuration

## Issue Resolution

The driver was failing with "websocket: bad handshake" errors due to incorrect TrueNAS connection URL.

### Solution

**TrueNAS Scale API should use encrypted WebSocket connection with certificate verification disabled:**
- Protocol: `wss://` (encrypted WebSocket)
- Port: `443` (HTTPS)

The driver **already has InsecureSkipVerify enabled** for `wss://` connections in `pkg/tnsapi/client.go`, which allows secure encryption in transit while working around self-signed certificate issues.

## Updating the Secret

The `tns-csi-credentials` secret must use the correct URL format:

```bash
export KUBECONFIG=~/.kube/homelab-kubeconfig.yaml

# Delete old secret
kubectl delete secret -n kube-system tns-csi-credentials

# Create new secret with correct URL
kubectl create secret generic tns-csi-credentials \
  -n kube-system \
  --from-literal=url='wss://10.10.20.100:443/api/current' \
  --from-literal=api-key='YOUR_TRUENAS_API_KEY'
```

Replace:
- `10.10.20.100` with your TrueNAS IP
- `YOUR_TRUENAS_API_KEY` with your actual API key from TrueNAS System > API Keys

Then restart the pods:
```bash
kubectl delete pod -n kube-system -l app.kubernetes.io/name=tns-csi-driver
```

## Automating via Secret Management

To make this permanent and managed through Flux, add the URL to your encrypted secrets. Update your `cluster-secrets.sops.yaml`:

```yaml
TNS_URL: "wss://10.10.20.100:443/api/current"
TNS_API_KEY: "your-api-key"
```

Then reference it in the HelmRelease through environment variable substitution.

## Certificate Verification

The code in `pkg/tnsapi/client.go` already handles this:

```go
if strings.HasPrefix(c.url, "wss://") {
    dialer.TLSClientConfig = &tls.Config{
        InsecureSkipVerify: true,
    }
}
```

This means if you ever want to use `wss://` with a self-signed certificate, it will work without modification.
