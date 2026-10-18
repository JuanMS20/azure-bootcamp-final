#!/usr/bin/env bash
# Elimina TODO el Resource Group del proyecto (buena práctica de costos del bootcamp).
set -euo pipefail
RG="${RG:-rg-bootcamp-final}"
az group delete --name "$RG" --yes --no-wait
echo "Eliminación de $RG solicitada."
