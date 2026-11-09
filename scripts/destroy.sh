#!/usr/bin/env bash
# =============================================================================
# Script de destrucción controlada (teardown) de infraestructura en Azure
# Compatible con Git Bash, Linux y macOS
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARDWARE_DIR="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$HARDWARE_DIR/infra"
TEMPLATE_DIR="$INFRA_DIR/plantillas"
PARAM_DIR="$INFRA_DIR/parametros"

echo "============================================================"
echo "  Destrucción Controlada de Infraestructura en Azure"
echo "============================================================"

read -p "Escribe 'destroy' para confirmar la eliminación de la infraestructura: " confirm
if [ "$confirm" != "destroy" ]; then
    echo "[CANCELADO] Operación abortada por el usuario. No se eliminó ningún recurso."
    exit 0
fi

INFRA_FILE="$PARAM_DIR/infra.tfvars"
BACKEND_FILE="$PARAM_DIR/backend.tfvars"
FRONT_FILE="$PARAM_DIR/frontend.tfvars"

cd "$TEMPLATE_DIR"
tofu destroy -auto-approve \
    -var-file="$INFRA_FILE" \
    -var-file="$BACKEND_FILE" \
    -var-file="$FRONT_FILE"

echo "[OK] Infraestructura destruida exitosamente en Azure."

