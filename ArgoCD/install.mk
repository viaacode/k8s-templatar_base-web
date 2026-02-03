NAMESPACE := argocd
TMPL_PATH := ./
K8S_CTX   ?= aks-tst
ENV       ?= int
AKS_CTX   ?= aks-tst

export LOCAL_DOMAIN 


.PHONY: install set-ns setup_app ingress get-pass

install: set-ns setup_app ingress get-pass

set-ns:
	@kubectl config use-context $(K8S_CTX)
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=$(NAMESPACE)

setup_app: set-ns
	#@bash setup_argocd.sh
	@kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#	@bash setup_argocd_cmd.sh

mk_cert: set-ns
	@mkcert *.$${LOCAL_DOMAIN}
	@kubectl -n $(NAMESPACE)  create secret tls star-subdomain-local --cert=./_wildcard.$${LOCAL_DOMAIN}.pem --key=_wildcard.$${LOCAL_DOMAIN}-key.pem||true && \
  rm ./_wildcard*.pem

ingress: set-ns mk_cert
	APP_NAME=argocd-server LOCAL_DOMAIN=$(LOCAL_DOMAIN) NAMESPACE=$(NAMESPACE) \
	SVC_NAME=argocd-server SVC_PORT=443 \
	ENV=$(ENV) envsubst < $(TMPL_PATH)/ing-ssl-tmpl.yaml | kubectl apply -f -

get-pass: set-ns
	@kubectl -n $(NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo ""

clean: set-ns
	@echo "🧹 Cleaning Argo CD..."
	@# 1. Delete all Applications first to trigger cascading deletion
	@kubectl delete applications --all -n $(NAMESPACE) --ignore-not-found --timeout=30s || true
	@# 2. Force remove finalizers if they are stuck (common issue)
	@kubectl get applications -n $(NAMESPACE) -o name | xargs -r kubectl patch -n $(NAMESPACE) --type=merge -p '{"metadata":{"finalizers":[]}}'
	@# 3. Now delete the namespace
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found
	@echo "✅ Argo CD Cleaned."
