# --- ESO Vault Kubernetes auth integration ---------------------------------
NAMESPACE       ?= playground
APP_NS          ?= $${NAMESPACE}
K8S_CTX         ?= $(K8S_CTX)
VAULT_ADDR      ?= $${VAULT_ADDR}
## unset for local bao
VAULT_NAMESPACE ?= admin
ESO_ROLE        ?= eso-$(APP_NS)-$(ENV)
POLICY_NAME     ?= eso-$(APP_NS)-$(ENV)

# What secret path you want ESO to read
VAULT_SECRET_PATH ?= *
#/*
export VAULT_SECRET_PATH
.PHONY: vault_k8s_auth_enable vault_k8s_auth_config vault_policy vault_role vault_eso_bootstrap

vault_k8s_auth_enable:
	@bao auth enable -namespace=$(VAULT_NAMESPACE) kubernetes >/dev/null 2>&1 || true

vault_k8s_auth_config: vault_k8s_auth_enable
	@echo "Configuring Vault Kubernetes auth using token reviewer SA (external-secrets/vault-token-reviewer)"
	@K8S_HOST="$$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"; \
	echo __________________ $$K8S_HOST;\
	kubectl -n external-secrets create token vault-token-reviewer --duration=24h > /tmp/reviewer.jwt; \
	kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/ca.crt; \
	bao write -namespace=$(VAULT_NAMESPACE) auth/kubernetes/config \
	  kubernetes_host="$$K8S_HOST" \
	  kubernetes_ca_cert=@/tmp/ca.crt \
	  token_reviewer_jwt=@/tmp/reviewer.jwt >/dev/null

vault_policy:
	envsubst < ./vault-token-reviewer-tmpl.yaml | kubectl apply -f-
	$(MAKE) -f ../ExternalSecrets/eso_vault.mk eso_vault_sa
	@echo "Writing Vault policy $(POLICY_NAME) for kv-$(ENV)/data/$(VAULT_SECRET_PATH)"
	printf '%s\n' \
	  'path "kv-$(ENV)/data/$(VAULT_SECRET_PATH)" {' \
	  '  capabilities = ["create", "update", "read", "delete"]' \
	  '} '\
	  'path "kv-qas/metadata/*" {' \
	  '  capabilities = ["list", "read", "delete"]' \
	  '}'  > /tmp/$(POLICY_NAME).hcl

	@bao policy write -namespace=$(VAULT_NAMESPACE) $(POLICY_NAME) /tmp/$(POLICY_NAME).hcl >/dev/null

vault_role: vault_policy
	@echo "Writing Vault k8s role $(ESO_ROLE) bound to SA eso-vault in ns $(APP_NS)"
	@bao write -namespace=$(VAULT_NAMESPACE) auth/kubernetes/role/$(ESO_ROLE) \
	  bound_service_account_names=eso-vault \
	  bound_service_account_namespaces=$(APP_NS) \
	  policies=$(POLICY_NAME) \
	  ttl=1h >/dev/null

# One-shot: enable + config + role/policy
vault_eso_bootstrap: vault_policy vault_k8s_auth_config vault_role
	@echo "✅ Vault Kubernetes auth ready for ESO role=$(ESO_ROLE)"
