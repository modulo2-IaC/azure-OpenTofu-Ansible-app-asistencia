#!/usr/bin/env bash
# =============================================================================
# SCRIPT DE AUTOMATIZACIÓN (BASH): VALIDACIÓN, ESCANEO Y DESPLIEGUE EN AZURE
# Sistema de Asistencia - OpenTofu Modular (Alta Cohesión / Bajo Acoplamiento)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$ROOT_DIR/plantillas"
PARAM_DIR="$ROOT_DIR/parametros"

ENVIRONMENT="${1:-dev}"
LOCATION="${2:-swedencentral}"

echo "============================================================"
echo "  Despliegue OpenTofu: Sistema de Asistencia (Azure)"
echo "============================================================"
echo "Entorno     : $ENVIRONMENT"
echo "Ubicación   : $LOCATION"
echo "Plantillas  : $TEMPLATE_DIR"
echo "Parámetros  : infra.tfvars, backend.tfvars, frontend.tfvars"

# 0. Verificación de archivos
INFRA_FILE="$PARAM_DIR/infra.tfvars"
BACKEND_FILE="$PARAM_DIR/backend.tfvars"
FRONT_FILE="$PARAM_DIR/frontend.tfvars"

for f in "$INFRA_FILE" "$BACKEND_FILE" "$FRONT_FILE"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] No se encontró el archivo: $f"
        echo "Por favor copia los archivos *.example.tfvars y configúralos con tus valores."
        exit 1
    fi
done

# 1. Escaneos y formato
echo -e "\n[1/3] Verificando formato y calidad de código..."
cd "$TEMPLATE_DIR"
tofu fmt -check -recursive || echo "[WARN] Se encontraron discrepancias de formato."

# 2. Verificación y auto-aprovisionamiento de bootstrap
echo -e "\n[2/4] Verificando almacenamiento del estado remoto en Azure (bootstrap)..."
RG_STATE="rg-asistencia-tfstate"
ST_STATE="sttofuasistenciadev"

if command -v az &> /dev/null; then
    if ! az storage account show --name "$ST_STATE" --resource-group "$RG_STATE" &> /dev/null; then
        echo "[AVISO] Storage Account no encontrado. Aprovisionando bootstrap..."
        BOOTSTRAP_DIR="$(dirname "$ROOT_DIR")/bootstrap"
        cd "$BOOTSTRAP_DIR"
        tofu init
        tofu apply -auto-approve
        echo "[OK] Bootstrap aprovisionado exitosamente."
        cd "$TEMPLATE_DIR"
    else
        echo "[OK] Storage Account '$ST_STATE' activo en Azure."
    fi
fi

# 3. Inicialización
echo -e "\n[3/4] Inicializando OpenTofu en plantillas/..."
cd "$TEMPLATE_DIR"
tofu init
tofu validate

# 4. Plan y Despliegue
echo -e "\n[4/4] Aplicando infraestructura en Azure..."
tofu apply -auto-approve \
    -var-file="$INFRA_FILE" \
    -var-file="$BACKEND_FILE" \
    -var-file="$FRONT_FILE"

echo -e "\n============================================================"
echo "  ¡Despliegue Completado Exitosamente en Azure!"
echo "============================================================"
tofu output
