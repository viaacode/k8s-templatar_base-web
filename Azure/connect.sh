az account set --subscription ${ENV}
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CTX}  --overwrite-existing
