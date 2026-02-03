APP_NS ?= $${NAMESPACE}
ENV    ?= qas
ENVS   ?= int qas prd
PREFIX ?= $${PREFIX}
SUFFIX ?=$${SUFFIX}
export PREFIX SUFFIX
.PHONY: all eso_refresh eso_vault_sa eso_secretstore eso_vault_setup

all: eso_vault_sa eso_vault_setup
default: all

eso_vault_sa:
	@kubectl create namespace $(APP_NS) --dry-run=client -o yaml | kubectl apply -f -
	@APP_NS=$(APP_NS) envsubst < ../Vault/eso-vault-tmpl.yaml | kubectl apply -f -

eso_secretstore: eso_vault_sa
	@echo "Applying SecretStore vault-backend to $(APP_NS) for ENV=$(ENV)"
	@APP_NS=$(APP_NS) ENV=$(ENV) VAULT_ADDR=$${VAULT_ADDR} envsubst < ../Vault/secretstore-provider-k8s-tmpl.yaml | kubectl apply -f -

eso_refresh:
	@kubectl -n $(APP_NS) annotate externalsecret \
	  $(PREFIX)-$${APP_NAME}-vault-$(SUFFIX) \
	  externalsecrets.external-secrets.io/refresh-now="$$(date +%s)" --overwrite || true

# Full: assumes ESO already installed; just sets app ns SA + SecretStore
eso_vault_setup: eso_secretstore
	@kubectl -n $(APP_NS) get secretstore $(PREFIX)-vault-backend
