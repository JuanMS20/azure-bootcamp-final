#!/usr/bin/env bash
# Despliegue manual desde Azure Cloud Shell (alternativa al pipeline).
# Uso:  ADMIN_IP="190.1.2.3/32" bash scripts/deploy.sh
set -euo pipefail

: "${ADMIN_IP:?Define ADMIN_IP con tu IP pública en formato CIDR, ej: ADMIN_IP=190.1.2.3/32}"
RG="${RG:-rg-bootcamp-final}"
LOCATION="${LOCATION:-westus3}"
ENV_NAME="${ENV_NAME:-dev}"
PREFIX="${PREFIX:-bootc}"

az group create --name "$RG" --location "$LOCATION" --tags proyecto=bootcamp-azure-final

echo ">> What-if"
az deployment group what-if \
  --resource-group "$RG" \
  --template-file infra/main.bicep \
  --parameters envName="$ENV_NAME" prefix="$PREFIX" adminSourceIp="$ADMIN_IP"

echo ">> Deploy"
az deployment group create \
  --name "deploy-manual-$(date +%s)" \
  --resource-group "$RG" \
  --template-file infra/main.bicep \
  --parameters envName="$ENV_NAME" prefix="$PREFIX" adminSourceIp="$ADMIN_IP" \
  --query properties.outputs

az resource list --resource-group "$RG" --output table
