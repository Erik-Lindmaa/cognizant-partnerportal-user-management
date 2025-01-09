RESOURCE_GROUP='rg-spoke-AppInte-nonprod-001-nonprod-003-az03'
location='swedencentral'
owner='elindmaa@aurobay.com'
costCenter='64460'
PARAM_FILE='parameters.json'
TEMPLATE_FILE='main.bicep'

# az account set --subscription "AppInte-nonprod-001"
# RG Group creation
#az group create --name "$RESOURCE_GROUP" --location "$location" --tags Owner="$owner" CostCenter="$costCenter"

# Deploy
az deployment group create --resource-group "$RESOURCE_GROUP" --template-file "$TEMPLATE_FILE" --parameters "@$PARAM_FILE"