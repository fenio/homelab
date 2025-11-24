# TNS CSI Driver - Connection Configuration

## Issue Resolution

The driver was failing with "websocket: bad handshake" errors due to incorrect TrueNAS connection URL.

### Solution

**TrueNAS Scale API requires unencrypted WebSocket connection over HTTP:**
- Protocol: `ws://` (not `wss://`)
- Port: `80` (not `443`)

The driver **already has InsecureSkipVerify enabled** for `wss://` connections, but your TrueNAS doesn't expose the WebSocket API over HTTPS with a valid certificate.

## Updating the Secret

The `tns-csi-credentials` secret must use the correct URL format:

```bash
export KUBECONFIG=~/.kube/homelab-kubeconfig.yaml

# Delete old secret
kubectl delete secret -n kube-system tns-csi-credentials

# Create new secret with correct URL
kubectl create secret generic tns-csi-credentials \
  -n kube-system \
  --from-literal=url='ws://10.10.20.100:80/api/current' \
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
TNS_URL: "ws://10.10.20.100:80/api/current"
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
