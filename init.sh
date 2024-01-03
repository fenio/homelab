kubectl apply --server-side --kustomize ./cluster/bootstrap/flux
export SOPS_AGE_KEY_FILE=~/AGE/sops-key.txt
sops --decrypt cluster/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/bootstrap/flux/github-deploy-key.sops.yaml | kubectl apply -f -
kubectl create namespace network
sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f cluster/flux/vars/cluster-settings.yaml
kubectl apply --server-side --kustomize ./cluster/flux/config
