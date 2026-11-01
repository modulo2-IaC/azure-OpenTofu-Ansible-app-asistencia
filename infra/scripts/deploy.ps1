# =============================================================================
# SCRIPT DE AUTOMATIZACIÓN: VALIDACIÓN, ESCANEO Y DESPLIEGUE EN AZURE
# Sistema de Asistencia - OpenTofu Modular (Alta Cohesión / Bajo Acoplamiento)
# =============================================================================

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Environment = "dev",

    [Parameter()]
    [string]$Location = "swedencentral",

    [Parameter()]
    [switch]$SkipScan,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$AutoApprove = $true
)

$ErrorActionPreference = "Stop"
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir       = Split-Path -Parent $ScriptDir
$TemplateDir   = Join-Path $RootDir "plantillas"
$ParamDir      = Join-Path $RootDir "parametros"
$HardwareDir   = Split-Path -Parent $RootDir
$BootstrapDir  = Join-Path $HardwareDir "bootstrap"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  Despliegue OpenTofu: Sistema de Asistencia (Azure)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Entorno     : $Environment" -ForegroundColor Yellow
Write-Host "Ubicación   : $Location" -ForegroundColor Yellow
Write-Host "Plantillas  : $TemplateDir" -ForegroundColor Yellow
Write-Host "Parámetros  : infra.tfvars, backend.tfvars, frontend.tfvars" -ForegroundColor Yellow

# -----------------------------------------------------------------------------
# 1. VERIFICACIÓN DE PRERREQUISITOS Y PARÁMETROS
# -----------------------------------------------------------------------------
Write-Host "`n[1/5] Verificando herramientas y archivos de configuración..." -ForegroundColor Magenta

if (-not (Get-Command tofu -ErrorAction SilentlyContinue)) {
    Write-Host "  [ERROR] OpenTofu ('tofu') no está instalado o no se encuentra en el PATH." -ForegroundColor Red
    exit 1
}

$infraFile   = Join-Path $ParamDir "infra.tfvars"
$backendFile = Join-Path $ParamDir "backend.tfvars"
$frontFile   = Join-Path $ParamDir "frontend.tfvars"

foreach ($f in @($infraFile, $backendFile, $frontFile)) {
    if (-not (Test-Path $f)) {
        Write-Host "  [ERROR] No se encontró el archivo: $f" -ForegroundColor Red
        Write-Host "  Por favor copia los archivos *.example.tfvars y configúralos con tus valores." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "  [OK] Archivos de parámetros verificados correctamente." -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. ESCANEOS DEVSECOPS Y CONTROL DE CALIDAD
# -----------------------------------------------------------------------------
if (-not $SkipScan) {
    Write-Host "`n[2/5] Ejecutando análisis estático y de formato..." -ForegroundColor Magenta
    
    # 1.1 Formato de código
    Write-Host "  -> Verificando formato con 'tofu fmt'..." -ForegroundColor Cyan
    Push-Location $TemplateDir
    try {
        tofu fmt -check -recursive
        Write-Host "  [OK] Formateo correcto." -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Hay discrepancias de formato. Ejecuta 'tofu fmt' para corregirlas." -ForegroundColor Yellow
    } finally {
        Pop-Location
    }

    # 1.2 TFLint
    if (Get-Command tflint -ErrorAction SilentlyContinue) {
        Write-Host "  -> Ejecutando TFLint..." -ForegroundColor Cyan
        Push-Location $TemplateDir
        try {
            tflint --init 2>$null
            tflint --recursive
            Write-Host "  [OK] TFLint finalizado sin errores críticos." -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] TFLint reportó advertencias." -ForegroundColor Yellow
        } finally {
            Pop-Location
        }
    }

    # 1.3 Checkov
    if (Get-Command checkov -ErrorAction SilentlyContinue) {
        Write-Host "  -> Ejecutando escaneo de seguridad con Checkov..." -ForegroundColor Cyan
        checkov -d $TemplateDir --framework terraform --soft-fail --quiet
        Write-Host "  [OK] Escaneo Checkov concluido." -ForegroundColor Green
    }
}

# -----------------------------------------------------------------------------
# 3. VERIFICACIÓN Y AUTO-APROVISIONAMIENTO DE BOOTSTRAP (ESTADO REMOTO)
# -----------------------------------------------------------------------------
Write-Host "`n[3/5] Verificando almacenamiento del estado remoto en Azure (bootstrap)..." -ForegroundColor Magenta
$rgState = "rg-asistencia-tfstate"
$stState = "sttofuasistenciadev"
$storageExists = $false

if (Get-Command az -ErrorAction SilentlyContinue) {
    $rgCheck = (& az group exists --name $rgState 2>$null)
    if ($rgCheck -match "true") {
        $storageExists = $true
        Write-Host "  [OK] Storage Account '$stState' activo en Azure ($rgState)." -ForegroundColor Green
    }
}

if (-not $storageExists) {
    Write-Host "  [AVISO] El Resource Group '$rgState' no existe aún en Azure." -ForegroundColor Yellow
    Write-Host "  Aprovisionando automáticamente módulo bootstrap en '$BootstrapDir'..." -ForegroundColor Cyan
    Push-Location $BootstrapDir
    try {
        & tofu init
        if ($LASTEXITCODE -ne 0) { throw "tofu init en bootstrap falló con código $LASTEXITCODE" }
        & tofu apply -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "tofu apply en bootstrap falló con código $LASTEXITCODE" }
        Write-Host "  [OK] Módulo bootstrap aprovisionado con éxito." -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Falló la creación del Storage Account en bootstrap: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    } finally {
        Pop-Location
    }
}

# -----------------------------------------------------------------------------
# 4. INICIALIZACIÓN DE OPENTOFU
# -----------------------------------------------------------------------------
Write-Host "`n[4/5] Inicializando OpenTofu en plantillas/..." -ForegroundColor Magenta
Push-Location $TemplateDir
try {
    & tofu init
    if ($LASTEXITCODE -ne 0) { throw "tofu init en plantillas falló con código $LASTEXITCODE" }
    & tofu validate
    if ($LASTEXITCODE -ne 0) { throw "tofu validate en plantillas falló con código $LASTEXITCODE" }
    Write-Host "  [OK] OpenTofu inicializado y validado con éxito." -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Falló la inicialización o validación de OpenTofu: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# -----------------------------------------------------------------------------
# 5. PLAN Y APLICACIÓN DE LA INFRAESTRUCTURA
# -----------------------------------------------------------------------------
Write-Host "`n[5/5] Generando plan de ejecución..." -ForegroundColor Magenta
$planArgs = @(
    "plan",
    "-var-file=$infraFile",
    "-var-file=$backendFile",
    "-var-file=$frontFile",
    "-out=tfplan"
)

try {
    & tofu $planArgs
    if ($LASTEXITCODE -ne 0) { throw "tofu plan falló con código $LASTEXITCODE" }
    Write-Host "  [OK] Plan generado exitosamente en tfplan." -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Error al generar el plan de OpenTofu: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

if ($DryRun) {
    Write-Host "`n[INFO] Modo Dry-Run activado. No se realizarán cambios en Azure." -ForegroundColor Yellow
    Pop-Location
    exit 0
}

# -----------------------------------------------------------------------------
# 6. APLICACIÓN DE LA INFRAESTRUCTURA
# -----------------------------------------------------------------------------
Write-Host "`n[6/5] Aprovisionando infraestructura en Microsoft Azure..." -ForegroundColor Magenta
$applyArgs = @("apply")
if ($AutoApprove) {
    $applyArgs += "-auto-approve"
}
$applyArgs += "tfplan"

try {
    & tofu $applyArgs
    if ($LASTEXITCODE -ne 0) { throw "tofu apply falló con código $LASTEXITCODE" }
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "  ¡Despliegue Completado Exitosamente en Azure!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green

    # Mostrar resumen de salidas
    Write-Host "`n--- Resumen de Endpoints y Accesos ---" -ForegroundColor Cyan
    $frontUrl = (tofu output -raw frontend_url 2>$null)
    $frontIp  = (tofu output -raw frontend_ip_url 2>$null)
    $backApi  = (tofu output -raw backend_api_url 2>$null)
    $swagger  = (tofu output -raw swagger_docs_url 2>$null)

    Write-Host "Frontend Web (FQDN) : $frontUrl" -ForegroundColor Green
    Write-Host "Frontend Web (IP)   : $frontIp" -ForegroundColor Green
    Write-Host "Backend API         : $backApi" -ForegroundColor Yellow
    Write-Host "Documentación Swagger: $swagger" -ForegroundColor Yellow
    Write-Host "`nCredenciales Iniciales:" -ForegroundColor Cyan
    Write-Host "- Administrador     : Matrícula 123456789 / Contraseña 123456789" -ForegroundColor White
    Write-Host "- Estudiante Demo   : Matrícula 12345600  / Contraseña 12345600" -ForegroundColor White
} catch {
    Write-Host "  [ERROR] Ocurrió un error durante la ejecución de tofu apply." -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
