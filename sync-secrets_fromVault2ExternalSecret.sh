#!/bin/bash

# Configuration
bao_PATH="kv-qas/hetarchief-v3"
SECRET_NAME="hetarchief-v3-secrets"
NAMESPACE="hetarchief-v3"
STORE_NAME="bao-backend"

echo "Step 1: Listing all secret paths in $bao_PATH..."
PATHS=$(bao kv list -format=json "$bao_PATH" | jq -r '.[]')

# Initialize an empty array for our ExternalSecret data mappings
DATA_ENTRIES="[]"

for SUBPATH in $PATHS; do
    echo "  -> Fetching keys for: $SUBPATH"
    
    # Fetch the actual keys inside this secret (metadata contains the keys)
    # We use 'data.data' for KV-V2 engines
    KEYS=$(bao kv get -format=json "$bao_PATH/$SUBPATH" | jq -r '.data.data | keys[]')
    
    for KEY in $KEYS; do
        # We create a unique secretKey in K8s to avoid collisions 
        # (e.g., path_key or just key if you prefer)
        SAFE_KEY="${SUBPATH}_${KEY}"
        
        DATA_ENTRIES=$(echo "$DATA_ENTRIES" | jq ". += [{
            secretKey: \"$SAFE_KEY\",
            remoteRef: {
                key: \"$bao_PATH/$SUBPATH\",
                property: \"$KEY\"
            }
        }]")
    done
done

echo "Step 2: Generating ExternalSecret manifest..."

# Convert JSON array to YAML format
YAML_DATA=$(echo "$DATA_ENTRIES" | jq -r '.[] | "  - secretKey: \(.secretKey)\n    remoteRef:\n      key: \(.remoteRef.key)\n      property: \(.remoteRef.property)"')

cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: $STORE_NAME
    kind: SecretStore
  target:
    name: $SECRET_NAME-sync
    creationPolicy: Owner
  data:
$YAML_DATA
EOF

echo "Done! ExternalSecret '$SECRET_NAME' has been updated with all subpath keys."

