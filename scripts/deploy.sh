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

    tofu apply tfplan
    echo "[OK] Infraestructura Cloud desplegada exitosamente."

    FRONT_URL=$(tofu output -raw frontend_url 2>/dev/null || true)
    BACK_API=$(tofu output -raw backend_api_url 2>/dev/null || true)
    DB_IP=$(tofu output -raw database_private_ip 2>/dev/null || true)
    echo "Frontend Web : $FRONT_URL"
    echo "Backend API  : $BACK_API"
    echo "Database VM  : $DB_IP:5432 (Privada VNet)"

    cd "$HARDWARE_DIR"
fi

# -----------------------------------------------------------------------------
# FASE 2: GESTIÓN DE CONFIGURACIÓN Y DESPLIEGUE (Ansible)
# -----------------------------------------------------------------------------
if [ "$TARGET" = "all" ] || [ "$TARGET" = "ansible" ]; then
    echo -e "\n>>> [FASE 2] Aprovisionando Software y Configuración con Ansible..."
    
    # Verificación SSH con reintentos mientras las VMs inician el SO
    MAX_ATTEMPTS=12
    ATTEMPT=1
    CONNECTED=0

    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        echo "     [Intento $ATTEMPT/$MAX_ATTEMPTS] Probando SSH hacia las VMs (esperando inicialización del SO)..."
        if "$SCRIPT_DIR/run-ansible.sh" ping > /dev/null 2>&1; then
            CONNECTED=1
            echo "     [OK] Todas las máquinas virtuales responden correctamente vía SSH."
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
            sleep 10
        fi
    done

    if [ $CONNECTED -ne 1 ]; then
        echo "[ERROR] Falló la conectividad SSH tras $MAX_ATTEMPTS intentos."
        exit 1
    fi

    "$SCRIPT_DIR/run-ansible.sh" deploy

    echo -e "\n============================================================"
    echo "  ¡Despliegue Integral Completado con Éxito!"
    echo "============================================================"
fi
