#!/bin/bash

#set temp context
K8S_CTX=aks-tst NAMESPACE=argocd make -C ../RBAC set-ns all_admin get_admin_token_file get_ca

# --- CONFIGURATION ---
CLUSTER_NAME="aks-int"        # Name as it will appear in Argo CD
SERVER_URL="`K8S_CTX=aks-tst NAMESPACE=argocd make -C ../RBAC get_server`"  # Remote API Server URL
ARGOCD_NAMESPACE="argocd"               # Namespace where Argo CD is installed
SA_TOKEN="`cat ../RBAC/token.txt`"            # The SA Token
CA_CERT_PATH="../RBAC/ca.crt"                 # Path to your ca.crt file

# 1. Base64 encode the CA Certificate
CA_DATA=$(cat $CA_CERT_PATH | base64 | tr -d '\n')

# 2. Construct the 'config' JSON
# This includes the token and the CA data for TLS verification
CONFIG_JSON=$(cat <<EOF
{
    "bearerToken": "$SA_TOKEN",
    "tlsClientConfig": {
      "caData": "$CA_DATA",
      "insecure": false
    }
}
EOF
)


# 3. Create the Secret in the Argo CD namespace
# Argo CD looks for the 'argoproj.io/secret-type: cluster' label
cat <<EOF | kubectl --context ${K8S_CTX} apply -n $ARGOCD_NAMESPACE -f -
apiVersion: v1
kind: Secret
metadata:
  name: cluster-${CLUSTER_NAME}
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${CLUSTER_NAME}
  server: ${SERVER_URL}
  config: |
    $CONFIG_JSON
EOF

echo "Cluster '$CLUSTER_NAME' has been registered to Argo CD."
