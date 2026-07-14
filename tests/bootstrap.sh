#!/usr/bin/env bash
# Provision a throwaway kind cluster for the chainsaw test suite.
# Idempotent: safe to run repeatedly. Run this once, then `chainsaw test`.
set -euo pipefail

CLUSTER="${CLUSTER:-gfu-labs}"
NODE_IMAGE="${NODE_IMAGE:-kindest/node:v1.32.2}"
CTX="kind-${CLUSTER}"

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "Creating kind cluster $CLUSTER ..."
  kind create cluster --name "$CLUSTER" --image "$NODE_IMAGE"
fi

kubectl --context "$CTX" wait --for=condition=Ready node --all --timeout=120s

echo "Installing metrics-server (HPA labs) ..."
kubectl --context "$CTX" apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl --context "$CTX" patch -n kube-system deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null || true

echo "Installing Gateway API CRDs (lab-21) ..."
kubectl --context "$CTX" apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

echo "Ensuring 'nextcloud' namespace exists (nextcloud dry-run tests) ..."
kubectl --context "$CTX" create namespace nextcloud --dry-run=client -o yaml | kubectl --context "$CTX" apply -f -

echo "Done. Run the suite with:  chainsaw test tests"
