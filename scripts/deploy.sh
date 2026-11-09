#!/usr/bin/env bash
# =============================================================================
# Script unificado de despliegue: OpenTofu + Ansible (Microsoft Azure)
# Compatible con Git Bash, Linux y macOS
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARDWARE_DIR="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$HARDWARE_DIR/infra"
TEMPLATE_DIR="$INFRA_DIR/plantillas"
PARAM_DIR="$INFRA_DIR/parametros"
BOOTSTRAP_DIR="$HARDWARE_DIR/bootstrap"

TARGET="${1:-all}"
ENVIRONMENT="${2:-dev}"
LOCATION="${3:-swedencentral}"

echo "============================================================"
echo "  Despliegue Unificado: OpenTofu + Ansible (Azure)"
echo "============================================================"
echo "Directorio Raíz : $HARDWARE_DIR"
echo "Objetivo        : $TARGET"
echo "Entorno         : $ENVIRONMENT"

# -----------------------------------------------------------------------------
# FASE 1: INFRAESTRUCTURA CLOUD (OpenTofu)
# -----------------------------------------------------------------------------
if [ "$TARGET" = "all" ] || [ "$TARGET" = "infra" ]; then
    echo -e "\n>>> [FASE 1] Aprovisionando Infraestructura Cloud con OpenTofu..."

    INFRA_FILE="$PARAM_DIR/infra.tfvars"
    BACKEND_FILE="$PARAM_DIR/backend.tfvars"
    FRONT_FILE="$PARAM_DIR/frontend.tfvars"

    for f in "$INFRA_FILE" "$BACKEND_FILE" "$FRONT_FILE"; do
        if [ ! -f "$f" ]; then
            echo "[ERROR] No se encontró el archivo: $f"
            exit 1
        fi
    done

    cd "$TEMPLATE_DIR"
    tofu fmt -check -recursive || true

    # Verificar bootstrap
    RG_STATE="rg-asistencia-tfstate"
    ST_STATE="sttofuasistenciadev"
    if command -v az &> /dev/null; then
        if ! az storage account show --name "$ST_STATE" --resource-group "$RG_STATE" &> /dev/null; then
            echo "[AVISO] Storage Account no encontrado. Aprovisionando bootstrap..."
            cd "$BOOTSTRAP_DIR"
            tofu init
            tofu apply -auto-approve
            cd "$TEMPLATE_DIR"
        fi
    fi

    tofu init
    tofu validate
    tofu plan \
        -var-file="$INFRA_FILE" \
        -var-file="$BACKEND_FILE" \
        -var-file="$FRONT_FILE" \
        -out=tfplan

    tofu apply -auto-approve tfplan
    echo "[OK] Infraestructura Cloud desplegada exitosamente."
    cd "$HARDWARE_DIR"
fi

# -----------------------------------------------------------------------------
# FASE 2: GESTIÓN DE CONFIGURACIÓN Y DESPLIEGUE (Ansible)
# -----------------------------------------------------------------------------
if [ "$TARGET" = "all" ] || [ "$TARGET" = "ansible" ]; then
    echo -e "\n>>> [FASE 2] Aprovisionando Software y Configuración con Ansible..."
    "$SCRIPT_DIR/run-ansible.sh" ping
    "$SCRIPT_DIR/run-ansible.sh" deploy

    echo -e "\n============================================================"
    echo "  ¡Despliegue Integral Completado con Éxito!"
    echo "============================================================"
fi

