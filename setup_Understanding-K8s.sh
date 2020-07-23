#!/bin/bash

ACR_NAME=msfukuissampleACRRegistry
ACR_RES_GROUP=$ACR_NAME

SP_NAME=sample-azr-service-principal

AKS_CLUSTER_NAME=AKSCluster
AKS_RES_GROUP=$AKS_CLUSTER_NAME

FOR_BUILD_DIR="./Understanding-K8s/chap02"
FOR_DELETE_SCRIPT="./delete_Understanding-K8s.$$.sh"

AKS_NODE_COUNT=3
AKS_K8S_VERSION=1.16.10
AKS_VM_SIZE="Standard_F2s_v2"

az group create --resource-group $ACR_RES_GROUP --location japaneast
az acr create --resource-group $ACR_RES_GROUP --name $ACR_NAME --sku Standard --location japaneast

ACR_ID=`az acr show --name $ACR_NAME --query id --output tsv`
echo "ACR_ID: [$ACR_ID]"
LOGIN_SERVER=`az acr show --name $ACR_NAME --query loginServer --output tsv`
echo "LOGIN_SERVER: [$LOGIN_SERVER]"

pushd $FOR_BUILD_DIR
az acr build --registry $ACR_NAME --image photo-view:v1.0 v1.0/
az acr build --registry $ACR_NAME --image photo-view:v2.0 v2.0/
az acr repository show-tags --name $ACR_NAME --repository photo-view --output table
popd

SP_PASSWD=$(az ad sp create-for-rbac --name $SP_NAME --role Reader --scopes $ACR_ID --query password --output tsv)

APP_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)

echo "SP_PASSWD: [$SP_PASSWD]"
echo "APP_ID: [$APP_ID]"

#az group create --resource-group $AKS_RES_GROUP --location japaneast

az aks create --name $AKS_CLUSTER_NAME --resource-group $AKS_RES_GROUP --node-count $AKS_NODE_COUNT --kubernetes-version $AKS_K8S_VERSION --node-vm-size $AKS_VM_SIZE --generate-ssh-keys --service-principal $APP_ID --client-secret $SP_PASSWD

az aks get-credentials --admin --resource-group $AKS_RES_GROUP --name $AKS_CLUSTER_NAME

echo "#############" > $FOR_DELETE_SCRIPT
echo "# for delete." >> $FOR_DELETE_SCRIPT
echo "#############" >> $FOR_DELETE_SCRIPT
echo "az group delete --name $ACR_RES_GROUP" >> $FOR_DELETE_SCRIPT
echo "az group delete --name $AKS_RES_GROUP" >> $FOR_DELETE_SCRIPT
echo "az ad sp delete --id=$APP_ID" >> $FOR_DELETE_SCRIPT

chmod 750 $FOR_DELETE_SCRIPT
cat $FOR_DELETE_SCRIPT
