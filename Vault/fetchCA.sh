K8S_HOST="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
kubectl get secret -n playground $(kubectl -n playground get sa vault-token-reviewer -o jsonpath='{.secrets[0].name}') \
  -o jsonpath='{.data.token}' | base64 -d > /tmp/reviewer.jwt

kubectl config view --raw --minify --flatten \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d |tee  /tmp/ca.crt
