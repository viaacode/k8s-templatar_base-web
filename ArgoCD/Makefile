# --- ArgoCD / config repo bootstrap -----------------------------------------
ARGOCD_NS            ?= argocd

# Choose auth mode: https or ssh
CFG_AUTH             := https

# HTTPS auth vars (CFG_AUTH=https)
CFG_GIT_USERNAME     ?= $${GIT_USER}
CFG_GIT_TOKEN        ?= $${GIT_PASSWORD}

# SSH auth vars (CFG_AUTH=ssh)
CFG_REPO_SSH_URL     ?=   # e.g. git@github.com:org/repo.git
CFG_GIT_SSH_KEY_FILE ?=   # path to deploy key file
NAMESPACE            ?= $(ARGOCD_NS)


.PHONY: argocd-bootstrap argocd-apply-projects argocd-apply-repo-creds set-ns

set-ns:
	@kubectl config use-context $(K8S_CTX)
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@kubectl config set-context --current --namespace=$(NAMESPACE)



all: set-ns login
argocd_password: set-ns
	NAMESPACE=argocd kubectl -n $(NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo ""



argocd_login: set-ns
	kubectl config set-context --current --namespace argocd
	bash -c 'argocd login --core'

test_argocd: argocd_login
	@argocd app list


test: set-ns test_argocd



# --- ArgoCD bootstrap: create repo creds + projects + (optionally) apply root-app
argocd-bootstrap: set-ns argocd-apply-repo-creds argocd-apply-projects argocd-deploy-root-env

argocd-apply-projects:
	@echo "__applying ArgoCD projects__"
	@for e in $(ENVS); do \
	  ENV=$$e ARGOCD_NS=$(ARGOCD_NS) envsubst < argocd-project-tmpl.yaml | kubectl apply -f - ; \
	done

argocd-apply-repo-creds:
	@echo "__applying ArgoCD config-repo credentials (CFG_AUTH=$(CFG_AUTH))__"
ifeq ($(CFG_AUTH),https)
	@ARGOCD_NS=$(ARGOCD_NS) CFG_GIT_USERNAME=$(CFG_GIT_USERNAME) CFG_GIT_TOKEN=$(CFG_GIT_TOKEN) envsubst < argocd-repo-https-secret-tmpl.yaml | kubectl apply -f -
else ifeq ($(CFG_AUTH),ssh)
	@if [ -z "$(CFG_GIT_SSH_KEY_FILE)" ]; then echo "CFG_GIT_SSH_KEY_FILE is required for CFG_AUTH=ssh"; exit 2; fi
	@export CFG_GIT_SSH_KEY_INDENTED="$$(sed 's/^/    /' $(CFG_GIT_SSH_KEY_FILE))" ; \
	ARGOCD_NS=$(ARGOCD_NS) CFG_GIT_SSH_KEY_INDENTED="$$CFG_GIT_SSH_KEY_INDENTED" envsubst < argocd-repo-ssh-secret-tmpl.yaml | kubectl apply -f -
else
	@echo "Unknown CFG_AUTH: $(CFG_AUTH) (use https or ssh)"; exit 2
endif



