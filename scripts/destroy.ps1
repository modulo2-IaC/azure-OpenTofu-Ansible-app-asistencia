<#
.SYNOPSIS
    Script de destrucción controlada (teardown) de infraestructura en Azure.

.DESCRIPTION
    Elimina de forma segura y completa todos los recursos aprovisionados
    en Microsoft Azure mediante OpenTofu (PostgreSQL, Backend NestJS, Frontend Vite).

.EXAMPLE
    .\scripts\destroy.ps1
    .\scripts\destroy.ps1 -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir    = $PSScriptRoot
$HardwareDir  = Split-Path -Parent $ScriptDir
$InfraDir     = Join-Path $HardwareDir "infra"
$TemplateDir  = Join-Path $InfraDir "plantillas"
$ParamDir     = Join-Path $InfraDir "parametros"

Write-Host "`n============================================================" -ForegroundColor Red
Write-Host "  Destrucción Controlada de Infraestructura en Azure (3-Tier)" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red

# 1. Confirmación de seguridad
if (-not $Force) {
    Write-Host "`n[PELIGRO] Esta acción eliminará permanentemente:" -ForegroundColor Red
    Write-Host "  - Máquinas Virtuales Linux (Base de Datos PostgreSQL, Backend NestJS, Frontend React)" -ForegroundColor Red
    Write-Host "  - IPs Públicas Estáticas y Tarjetas de Red (NICs)" -ForegroundColor Red
    Write-Host "  - Firewalls NSG y Asociaciones de Red" -ForegroundColor Red
    Write-Host "  - Red Virtual (VNet) y Subredes (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)" -ForegroundColor Red
    Write-Host "  - Log Analytics Workspace y Alertas de Azure Monitor" -ForegroundColor Red
    Write-Host "  - Resource Group completo en Azure" -ForegroundColor Red
    
    $confirm = Read-Host "`nEscribe 'destroy' para confirmar la eliminación de la infraestructura"
    if ($confirm -ne "destroy") {
        Write-Host "  [CANCELADO] Operación abortada por el usuario. No se eliminó ningún recurso." -ForegroundColor Yellow
        exit 0
    }
}

# 2. Ejecutar OpenTofu destroy
Write-Host "`n[1/1] Ejecutando tofu destroy en plantillas/..." -ForegroundColor Magenta

$infraFile   = Join-Path $ParamDir "infra.tfvars"
$backendFile = Join-Path $ParamDir "backend.tfvars"
$frontFile   = Join-Path $ParamDir "frontend.tfvars"

Push-Location $TemplateDir
try {
    tofu destroy -auto-approve `
        -var-file="$infraFile" `
        -var-file="$backendFile" `
        -var-file="$frontFile"

    if ($LASTEXITCODE -ne 0) { throw "tofu destroy falló con código $LASTEXITCODE" }
    Write-Host "`n[OK] Infraestructura destruida exitosamente en Microsoft Azure." -ForegroundColor Green
} finally {
    Pop-Location
}
