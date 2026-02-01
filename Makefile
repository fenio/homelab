# REQUIRED SECTION
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
include $(ROOT_DIR)/.mk-lib/common.mk

init:
	@kubectl apply --server-side --kustomize ./cluster/bootstrap/flux
	@export SOPS_AGE_KEY_FILE=~/AGE/sops-key.txt
	@sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
	@kubectl apply -f cluster/flux/vars/cluster-settings.yaml
	@kubectl apply --server-side --kustomize ./cluster/flux/config
nodes:
	@kubectl get nodes

kget:
	@$(kget)
