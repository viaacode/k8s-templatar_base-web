# --- Global settings --------------------------------------------------------
# acdmin or bot
RBAC_PROFILE               ?= admin
# above one of bot | helm | admin

OUT_YAML      ?= ./ci-rbac.yaml
CA_FILE       ?= ./ca.crt
TOKEN_FILE    ?= ./token.txt
CTX_NAME      ?= $(ENV)-$(RBAC_PROFILE)

# Map profile -> SA + Secret names
ifeq ($(RBAC_PROFILE),bot)
SA_NAME     := ci-bot
SECRET_NAME := ci-bot-token
else ifeq ($(RBAC_PROFILE),helm)
SA_NAME     := ci-helm
SECRET_NAME := ci-helm-token
TMPL_HELM        := sa-helm-tmpl.yaml
else ifeq ($(RBAC_PROFILE),admin)
SA_NAME     := ci-admin
SECRET_NAME := ci-admin-token
TMPL        := sa-cluster-admin-tmpl.yaml
else
$(error Unknown RBAC_PROFILE '$(RBAC_PROFILE)'; use bot|helm|admin)
endif


# Export these so sub-makefiles can see them
NAMESPACE                   ?= meemoo-infra
ENV                        ?= qas
CA_FILE                    ?= ./ca.crt
TOKEN_FILE                 ?= ./token.txt
CTX_NAME                   ?= $(ENV)-bot
K8S_CTX                    ?= aks-qas-auto


.PHONY: all get_ca64 set-ns gen apply get_token_file get_ca create_k8s_ctx clean all_admin

all: set-ns gen apply get_token_file get_ca create_k8s_ctx

all_admin:  set-ns gen apply get_admin_token_file get_ca create_k8s_ctx get_admin_token

export NAMESPACE ENV CTX_NAME K8S_CTX


set-ns:
	@kubectl config use-context $(K8S_CTX) || exit 1
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl config set-context --current --namespace $(NAMESPACE) >/dev/null

gen:
	@NAMESPACE="$(NAMESPACE)" envsubst < $(TMPL) > $(OUT_YAML)
	@echo "Generated $(OUT_YAML) from $(TMPL)"

apply:
	@kubectl --context $(K8S_CTX) apply -f $(OUT_YAML)


get_ca64: get_ca
	@cat ./ca.crt | base64



create_sa_yaml: set-ns
	@envsubst < $(TMPL) | tee ci-bot.yaml | kubectl apply -f -

get_token_file:
	@kubectl --context $(K8S_CTX) -n $(NAMESPACE) get secret ci-bot-token \
	  -o jsonpath='{.data.token}' | base64 -d > $(TOKEN_FILE)
	@chmod 600 $(TOKEN_FILE) 

get_admin_token_file:
	@kubectl --context $(K8S_CTX) -n $(NAMESPACE) get secret ci-admin-token \
          -o jsonpath='{.data.token}' | base64 -d > $(TOKEN_FILE)
	@chmod 600 $(TOKEN_FILE) 


get_token:
	@kubectl -n $(NAMESPACE) get secret ci-bot-token -o jsonpath='{.data.token}' | base64 -d; echo 

get_admin_token:
	@kubectl -n $(NAMESPACE) get secret ci-admin-token -o jsonpath='{.data.token}' | base64 -d; echo


export SA_TOKEN            := $(MAKE) get_token


get_ca:
	@kubectl --context $(K8S_CTX) -n $(NAMESPACE) get configmap kube-root-ca.crt \
	  -o jsonpath='{.data.ca\.crt}' > ./ca.crt
	@echo "Wrote CA to ./ca.crt"



# Helper: discover server URL for the context's cluster
get_server:
	@cluster="$$(kubectl config view -o jsonpath='{.contexts[?(@.name=="$(K8S_CTX)")].context.cluster}')"; \
	server="$$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$$cluster\")].cluster.server}")"; \
	echo "$$server"

create_k8s_ctx: 
	@cluster="$$(kubectl config view -o jsonpath='{.contexts[?(@.name=="$(K8S_CTX)")].context.cluster}')"; \
	server="$$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$$cluster\")].cluster.server}")"; \
	token="$$(cat $(TOKEN_FILE))"; \
	bash create-context_token.sh \
	  "$(CTX_NAME)" \
	  "$$server" \
	  "$(NAMESPACE)" \
	  "$(CA_FILE)" \
	  "$$token"

clean:
	@rm -f $(TOKEN_FILE) $(CA_FILE)
