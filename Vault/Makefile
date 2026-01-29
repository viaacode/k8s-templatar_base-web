absPathMakefile := $(abspath $(lastword $(MAKEFILE_LIST)))
wd              := $(shell dirname $(absPathMakefile))
WD              := $(wd)/
BIN_DIR         ?= ../bin
ENVS            := int qas prd
VAULT_ENGINE    ?= kv-int
TST_SEC         := demo
ENV             ?= int

#-namespace=admin -mount="kv-qas" "playground/cicd-helloworld-example-vault"

# --- Phony Targets ---
.PHONY: all  env_tokens put_ns-app-secret_key-value get_ns-app-secret_key list_ns-app-secret_keys create_kvs poli set_policy $(ENVS:$$=$$_poli) FORCE

# --- Main Entry Points ---
all: create_kvs  set_policy env_tokens

poli: $(ENVS:$$=$$_poli)

FORCE:

%_poli: test FORCE
	@echo "Generating and writing policy for: $*"
	ENV=$* envsubst < policy-tmpl.hcl > policy-$*.hcl
	ENV=$* bao policy write kv2-$*-admin "./policy-$*.hcl" >/dev/null 2>&1 || exit 1
	ENV=$* VAULT_TOKEN=$${VAULT_TOKEN_ROOT} bao token create -format=json -policy="kv2-$*-admin" > vault-$*.token

set_policy: test
	@if [ -f "./policy.hcl" ]; then \
		echo bao policy write kv2-admin "./policy.hcl" >/dev/null 2>&1 || exit 1; \
	fi
	$(MAKE) int_poli
	$(MAKE) qas_poli
	$(MAKE) prd_poli

#env_tokens:
#	ENV=int VAULT_TOKEN=$${VAULT_TOKEN_ROOT} bao token create -format=json -policy="kv2-$${ENV}-admin" > vault-$${ENV}.token
#	ENV=qas VAULT_TOKEN=$${VAULT_TOKEN_ROOT} bao token create -format=json -policy="kv2-$${ENV}-admin" > vault-$${ENV}.token
#	ENV=prd VAULT_TOKEN=$${VAULT_TOKEN_ROOT} bao token create -format=json -policy="kv2-$${ENV}-admin" > vault-$${ENV}.token

env_token:
	@cat vault-$(ENV).token | jq -r .auth.client_token

# --- KV Store Management (Bash Loop) ---
create_kvs:
	for env in $(ENVS); do \
		echo "Ensuring KV v2 engine is enabled at: kv-$$env"; \
		if ! bao secrets list | grep -q "^kv-$$env/"; then \
			bao secrets enable -path=kv-$$env kv-v2; \
		fi; \
		echo "KV store 'kv-$$env' is ready."; \
	done


# --- Helpers ---

test:
	@echo "Testing connection to $${VAULT_HOSTNAME}:$${VAULT_PORT}"
	bash -c '( > /dev/tcp/$${VAULT_HOSTNAME}/$${VAULT_PORT} || exit )'


list_ns-app-secret_keys:
	@echo "$(APP_NAME) has thes keys in $(VAULT_ADDR) using $(VAULT_ENGINE):"
	@bao kv get -format=json -mount=$(VAULT_ENGINE) $(NAMESPACE)/$(APP_NAME) | jq -r '.data.data | keys[]'


get_ns-app-secret_key:
	@echo "$(APP_NAME) key: $(SECRET_KEY) in $(VAULT_ADDR) using $(VAULT_ENGINE):"
	@SECRET_KEY=$${SECRET_KEY} bao kv get -format=json -mount=$(VAULT_ENGINE) $(NAMESPACE)/$(APP_NAME) | \
  jq -r '.data.data["$(SECRET_KEY)"]'

put_ns-app-secret_key-value:
	@echo "$(APP_NAME) key: $${KEY} willl be put in $(VAULT_ADDR) using $(VAULT_ENGINE):"
	@KEY=$${KEY}VALUE=$${VALUE} SECRET=$${SECRET}  bao kv put -mount=$(VAULT_ENGINE) $(NAMESPACE)/$(APP_NAME)/$(SECRET) $(KEY)=$(VALUE)

#bao kv get -format=json -mount=$(VAULT_ENGINE) $(NAMESPACE)/$(APP_NAME)

# refresh manual
#kubectl -n playground annotate externalsecret playground-cicd-helloworld-example-vault-qas   externalsecrets.external-secrets.io/refresh-now="$(date +%s)" --overwrite

