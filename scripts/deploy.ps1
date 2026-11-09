<#
.SYNOPSIS
    Script unificado de despliegue: OpenTofu + Ansible (Microsoft Azure).

.DESCRIPTION
    Aprovisiona la infraestructura cloud en Azure con OpenTofu (Fase 1) y
    posteriormente el software y configuración con Ansible (Fase 2).

.EXAMPLE
    .\scripts\deploy.ps1                    # Despliegue integral (Infraestructura + Ansible)
    .\scripts\deploy.ps1 -Target infra      # Aprovisiona únicamente la infraestructura con OpenTofu
    .\scripts\deploy.ps1 -Target ansible    # Configura únicamente el software con Ansible
    .\scripts\deploy.ps1 -DryRun            # Simulación sin aplicar cambios en Azure
    .\scripts\deploy.ps1 -SkipScan          # Despliegue rápido omitiendo análisis Checkov
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("all", "infra", "ansible")]
    [string]$Target = "all",

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
$ScriptDir    = $PSScriptRoot
$HardwareDir  = Split-Path -Parent $ScriptDir
$InfraDir     = Join-Path $HardwareDir "infra"
$TemplateDir  = Join-Path $InfraDir "plantillas"
$ParamDir     = Join-Path $InfraDir "parametros"
$BootstrapDir = Join-Path $HardwareDir "bootstrap"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  Despliegue Unificado: OpenTofu + Ansible (Azure)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Directorio Raíz : $HardwareDir" -ForegroundColor Yellow
Write-Host "Objetivo        : $Target" -ForegroundColor Yellow
Write-Host "Entorno         : $Environment" -ForegroundColor Yellow

# -----------------------------------------------------------------------------
# FASE 1: INFRAESTRUCTURA CLOUD (OpenTofu)
# -----------------------------------------------------------------------------
if ($Target -in @("all", "infra")) {
    Write-Host "`n>>> [FASE 1] Aprovisionando Infraestructura Cloud con OpenTofu..." -ForegroundColor Magenta

    # 1. Verificación de OpenTofu y parámetros
    if (-not (Get-Command tofu -ErrorAction SilentlyContinue)) {
        Write-Error "OpenTofu ('tofu') no está instalado o no se encuentra en el PATH."
        exit 1
    }

    $infraFile   = Join-Path $ParamDir "infra.tfvars"
    $backendFile = Join-Path $ParamDir "backend.tfvars"
    $frontFile   = Join-Path $ParamDir "frontend.tfvars"

    foreach ($f in @($infraFile, $backendFile, $frontFile)) {
        if (-not (Test-Path $f)) {
            Write-Error "No se encontró el archivo de parámetros: $f"
            exit 1
        }
    }

    # 2. Formato y análisis estático
    Push-Location $TemplateDir
    try {
        Write-Host "  -> Verificando formato de código..." -ForegroundColor Cyan
        tofu fmt -check -recursive
        if ($LASTEXITCODE -ne 0) { Write-Host "  [AVISO] Se detectaron diferencias menores de formato." -ForegroundColor Yellow }

        if (-not $SkipScan) {
            if (Get-Command checkov -ErrorAction SilentlyContinue) {
                Write-Host "  -> Ejecutando análisis de seguridad con Checkov (puede demorar unos segundos)..." -ForegroundColor Cyan
                checkov -d . --framework terraform --quiet --compact 2>&1 | Out-Null
            }
        }

        # 3. Verificación de almacenamiento de estado remoto (bootstrap)
        $rgState = "rg-asistencia-tfstate"
        $stState = "sttofuasistenciadev"
        if (Get-Command az -ErrorAction SilentlyContinue) {
            $stExists = az storage account show --name $stState --resource-group $rgState 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  -> Aprovisionando Storage Account de estado remoto en Azure..." -ForegroundColor Yellow
                Push-Location $BootstrapDir
                try {
                    tofu init
                    tofu apply -auto-approve
                } finally {
                    Pop-Location
                }
            }
        }

        # 4. Inicialización y Plan
        Write-Host "  -> Inicializando proveedores y módulos OpenTofu..." -ForegroundColor Cyan
        tofu init
        tofu validate
        if ($LASTEXITCODE -ne 0) { throw "tofu validate falló." }

        Write-Host "  -> Generando plan de ejecución (tfplan)..." -ForegroundColor Cyan
        $planArgs = @(
            "plan",
            "-var-file=$infraFile",
            "-var-file=$backendFile",
            "-var-file=$frontFile",
            "-out=tfplan"
        )
        & tofu $planArgs
        if ($LASTEXITCODE -ne 0) { throw "tofu plan falló con código $LASTEXITCODE" }

        if ($DryRun) {
            Write-Host "`n[INFO] Modo Dry-Run finalizado. No se realizan cambios en Azure." -ForegroundColor Yellow
            Pop-Location
            exit 0
        }

        # 5. Aplicación
        Write-Host "  -> Aplicando infraestructura en Azure..." -ForegroundColor Cyan
        & tofu apply "tfplan"
        if ($LASTEXITCODE -ne 0) { throw "tofu apply falló con código $LASTEXITCODE" }

        Write-Host "`n[OK] Infraestructura Cloud desplegada exitosamente." -ForegroundColor Green
        
        # Endpoints y URLs
        $frontUrl = (tofu output -raw frontend_url 2>$null)
        $frontIp  = (tofu output -raw frontend_ip_url 2>$null)
        $backApi  = (tofu output -raw backend_api_url 2>$null)
        $dbIp     = (tofu output -raw database_private_ip 2>$null)
        Write-Host "Frontend Web : $frontUrl ($frontIp)" -ForegroundColor Green
        Write-Host "Backend API  : $backApi" -ForegroundColor Yellow
        Write-Host "Database VM  : $dbIp:5432 (Privada VNet)" -ForegroundColor Cyan
    } finally {
        Pop-Location
    }
}

# -----------------------------------------------------------------------------
# FASE 2: GESTIÓN DE CONFIGURACIÓN Y DESPLIEGUE (Ansible)
# -----------------------------------------------------------------------------
if ($Target -in @("all", "ansible")) {
    Write-Host "`n>>> [FASE 2] Aprovisionando Software y Configuración con Ansible..." -ForegroundColor Magenta
    $AnsibleRunner = Join-Path $ScriptDir "run-ansible.ps1"

    # 1. Ping previo de comprobación con bucle de reintentos
    Write-Host "  -> Verificando conectividad SSH con las VMs en Azure..." -ForegroundColor Cyan
    $maxAttempts = 12
    $attempt = 1
    $connected = $false

    while ($attempt -le $maxAttempts -and -not $connected) {
        Write-Host "     [Intento $attempt/$maxAttempts] Probando SSH hacia las VMs (esperando inicialización del SO)..." -ForegroundColor Yellow
        $pingResult = & $AnsibleRunner "ping" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $connected = $true
            Write-Host "     [OK] Todas las máquinas virtuales responden correctamente vía SSH." -ForegroundColor Green
            break
        }
        $attempt++
        if ($attempt -le $maxAttempts) {
            Start-Sleep -Seconds 10
        }
    }

    if (-not $connected) {
        Write-Error "Fallo la conectividad SSH con las máquinas virtuales de Azure tras $maxAttempts intentos."
        exit 1
    }

    # 2. Despliegue de playbooks (Database -> Backend -> Frontend)
    Write-Host "  -> Aplicando playbooks de Ansible (PostgreSQL, NestJS, Vite, Nginx)..." -ForegroundColor Cyan
    & $AnsibleRunner "deploy"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Fallo la ejecución de los playbooks de Ansible."
        exit $LASTEXITCODE
    }

    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "  ¡Despliegue Integral Completado con Éxito!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
}
