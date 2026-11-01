#!/usr/bin/env bash
# =============================================================================
# SCRIPT DE AUTOMATIZACIÓN (BASH): DESTRUCCIÓN / TEARDOWN DE INFRAESTRUCTURA
# Sistema de Asistencia - Microsoft Azure con OpenTofu
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$ROOT_DIR/plantillas"
PARAM_DIR="$ROOT_DIR/parametros"

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
