.ONESHELL:
SHELL                          = /bin/bash
AKS_CTX                        ?= aks-tst
LOCAL_CONTEXT                  ?= kind-kind
LOCAL_BINDIR                   ?= /usr/local/bin/
INFRA_NS                       := $(or $(INFRA_NS), meemoo-infra)
LOCAL_CONTEXT                  := $(or $(LOCAL_CONTEXT), kind-kind)
TARGET_CONTEXT                 := $(or $(TARGET_CONTEXT), aks-tst)
TEST_DIR                       := $(WD)/test/
LOCAL_DOMAIN                   := ${LOCAL_DOMAIN:-kind.local}
absPathMakefile                := $(abspath $(lastword $(MAKEFILE_LIST)))
wd                             := `dirname $(absPathMakefile)`
WD                             := $(wd)/
SRC_DIR                        := $(WD)/src/
# bash ENV := ${ENV:int}
ENV                            := $(or $(ENV), int)
AKS_CTX                        ?= aks-tst
REMOTE_BIN_KUBELOGIN           := https://github.com/int128/kubelogin/releases/download/v1.35.2/kubelogin_linux_amd64.zip
RESOURCE_GROUP                 := rg-hetarchief-tst
SUBSCRIPTION                   ?= PRD
RG                             ?= rg-qas-eunorth
RG_REGESTRY		       := rg-hetarchief-tst
RG_TST                         := rg-hetarchief-tst
RG_QAS			       := rg-qas-eunorth


REGISTRY_HOST                  := meeregistrymoo.azurecr.io
#https://github.com/Azure/kubelogin/releases/download/v0.2.14/kubelogin-linux-amd64.zip

export SUBSCRIPTION LOCAL_CONTEXT K8S_CTX RG

.PHONY: all bind_acr2aks
all:  install-cli config end

.PHONY: end
end:
	kubectl config use-context $(AKS_CTX) &>/dev/null || ( exit 1;)

config:

	@echo "enabling export to terraform :)"
	@az provider register -n Microsoft.AzureTerraform

install-cli: login
	@echo "run: az aks install-cli if this fails"
	@ls $(LOCAL_BINDIR)/kubelogin || wget $(REMOTE_BIN_KUBELOGIN)-O $(LOCAL_BINDIR)/bin/kubelogin ; \
		chmod +x $(LOCAL_BINDIR)/bin/kubelogin
	@./install-az.sh || true
	RG=$(RG) SUBSCRIPTION=$(SUBSCRIPTION) AKS_CTX=$(AKS_CTX) ./connect.sh
login:
	@az login || true

# add registry to cluster
bind_acr2aks:
	@az aks update --name $(AKS_CTX) --resource-group $(RG) --attach-acr meeRegistrymoo
