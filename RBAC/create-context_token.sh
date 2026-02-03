#!/usr/bin/env bash
set -euo pipefail

CTX="${1:?context name required}"
SERVER="${2:?api server url required (https://...)}"
NAMESPACE="${3:-default}"
CA_FILE="${4:?path to CA cert file required}"
TOKEN="${5:?serviceaccount token required}"

CLUSTER_NAME="${CTX}-cluster"
USER_NAME="${CTX}-user"

kubectl config set-cluster "${CLUSTER_NAME}" \
  --server="${SERVER}" \
  --certificate-authority="${CA_FILE}" \
  --embed-certs=true

kubectl config set-credentials "${USER_NAME}" \
  --token="${TOKEN}"

kubectl config set-context "${CTX}" \
  --cluster="${CLUSTER_NAME}" \
  --user="${USER_NAME}" \
  --namespace="${NAMESPACE}"


echo "Created and switched to context: ${CTX}"

# Non-admin friendly checks (namespace-scoped)
kubectl --context ${CTX} -n "${NAMESPACE}" get sa "${CTX%-bot}" 2>/dev/null || true
kubectl --context ${CTX} -n "${NAMESPACE}" auth can-i list pods
kubectl --context ${CTX} -n "${NAMESPACE}" auth can-i list services
