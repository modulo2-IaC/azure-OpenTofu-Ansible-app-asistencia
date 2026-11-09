<#
.SYNOPSIS
    Lanzador de Ansible mediante contenedor Docker.

.DESCRIPTION
    Permite validar sintaxis, probar conectividad SSH, ejecutar modo check o desplegar
    los playbooks de Ansible en Azure sin necesidad de instalar Ansible nativamente en Windows.

.EXAMPLE
    .\scripts\run-ansible.ps1 syntax
    .\scripts\run-ansible.ps1 ping
    .\scripts\run-ansible.ps1 check
    .\scripts\run-ansible.ps1 deploy
    .\scripts\run-ansible.ps1 database
    .\scripts\run-ansible.ps1 backend
    .\scripts\run-ansible.ps1 frontend
    .\scripts\run-ansible.ps1 bash
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("syntax", "ping", "check", "deploy", "database", "backend", "frontend", "bash", "help")]
    [string]$Accion = "help",

    [Parameter(Position = 1)]
    [string]$ExtraArgs = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir   = $PSScriptRoot
$HardwareDir = Split-Path -Parent $ScriptDir
$AnsibleDir  = Join-Path $HardwareDir "ansible"

# 1. Validar si el motor de Docker está disponible
Write-Host "Verificando disponibilidad de Docker..." -ForegroundColor Cyan
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker Desktop no esta en ejecucion o el socket no responde. Inicia Docker Desktop en Windows y vuelve a intentar."
        exit 1
    }
} catch {
    Write-Error "No se pudo comunicar con Docker: $_"
    exit 1
}

# 2. Construir la imagen Docker si no existe
$ImageName = "asistencia-ansible:latest"
$imageExists = docker images -q $ImageName 2>$null
if (-not $imageExists) {
    Write-Host "Construyendo imagen Docker local '$ImageName'..." -ForegroundColor Yellow
    docker build -t $ImageName "$AnsibleDir"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Fallo la construccion de la imagen Docker de Ansible."
        exit 1
    }
}

# 3. Asegurar inventario disponible (crear desde ejemplo si aún no se ha ejecutado OpenTofu)
$InventoryFile = Join-Path $AnsibleDir "inventory\hosts.ini"
$InventoryExample = Join-Path $AnsibleDir "inventory\hosts.example.ini"
if (-not (Test-Path $InventoryFile) -and (Test-Path $InventoryExample)) {
    Copy-Item $InventoryExample $InventoryFile
}

# 4. Detectar ruta de llaves SSH del usuario en Windows
$SshDir = "$HOME\.ssh"
$SshVolume = ""
if (Test-Path $SshDir) {
    # Se monta en .ssh_host para que entrypoint.sh copie a .ssh con permisos estrictos 0600
    $SshVolume = "-v ${SshDir}:/root/.ssh_host:ro"
}

# 5. Determinar flags de TTY y comando base a ejecutar
$ttyFlag = ""
try {
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        $ttyFlag = "-t"
    }
} catch {
    $ttyFlag = ""
}

$DockerRunBase = "docker run --rm -i $ttyFlag -v `"${AnsibleDir}:/ansible`" $SshVolume -e ANSIBLE_HOST_KEY_CHECKING=False -w /ansible $ImageName"

switch ($Accion) {
    "syntax" {
        Write-Host "`n>>> [TEST 1] Verificando sintaxis de todos los playbooks..." -ForegroundColor Green
        Invoke-Expression "$DockerRunBase ansible-playbook -i inventory/hosts.ini playbooks/site.yml --syntax-check $ExtraArgs"
    }
    "ping" {
        Write-Host "`n>>> [TEST 2] Probando conectividad SSH y Python con las VMs..." -ForegroundColor Green
        Invoke-Expression "$DockerRunBase ansible all -i inventory/hosts.ini -m ping $ExtraArgs"
    }
    "check" {
        Write-Host "`n>>> [TEST 3] Ejecutando simulacion (--check --diff) sin aplicar cambios..." -ForegroundColor Green
        Invoke-Expression "$DockerRunBase ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check --diff $ExtraArgs"
    }
    "deploy" {
        Write-Host "`n>>> [DESPLIEGUE] Aplicando configuracion completa en Azure (site.yml)..." -ForegroundColor Yellow
        Invoke-Expression "$DockerRunBase ansible-playbook -i inventory/hosts.ini playbooks/site.yml $ExtraArgs"
    }
    "database" {
        Write-Host "`n>>> [DATABASE] Aprovisionando unicamente el Servidor PostgreSQL..." -ForegroundColor Yellow
        Invoke-Expression "$DockerRunBase ansible-playbook -i inventory/hosts.ini playbooks/database.yml $ExtraArgs"
    }
    "backend" {
        Write-Host "`n>>> [BACKEND] Aprovisionando unicamente el Backend NestJS..." -ForegroundColor Yellow
        Invoke-Expression "$DockerRunBase ansible-playbook -i inventory/hosts.ini playbooks/backend.yml $ExtraArgs"
    }
    "frontend" {
        Write-Host "`n>>> [FRONTEND] Aprovisionando unicamente el Frontend React/Vite..." -ForegroundColor Yellow
        Invoke-Expression "$DockerRunBase ansible-playbook -i inventory/hosts.ini playbooks/frontend.yml $ExtraArgs"
    }
    "bash" {
        Write-Host "`n>>> Abriendo terminal interactiva dentro del contenedor de Ansible..." -ForegroundColor Cyan
        Invoke-Expression "docker run --rm -it -v `"${AnsibleDir}:/ansible`" $SshVolume -e ANSIBLE_HOST_KEY_CHECKING=False -w /ansible $ImageName /bin/bash"
    }
    Default {
        Write-Host @"
Uso del script de pruebas de Ansible:
-------------------------------------
  .\scripts\run-ansible.ps1 syntax      Valida la sintaxis YAML y estructura de tareas.
  .\scripts\run-ansible.ps1 ping        Prueba la conexion SSH y modulo ping hacia Azure.
  .\scripts\run-ansible.ps1 check       Modo Dry-Run: simula ejecucion sin modificar las VMs.
  .\scripts\run-ansible.ps1 deploy      Ejecuta el aprovisionamiento real de toda la infraestructura.
  .\scripts\run-ansible.ps1 database    Aprovisiona solo el servidor de Base de Datos PostgreSQL.
  .\scripts\run-ansible.ps1 backend     Aprovisiona solo el servidor Backend.
  .\scripts\run-ansible.ps1 frontend    Aprovisiona solo el servidor Frontend.
  .\scripts\run-ansible.ps1 bash        Abre una consola Bash interactiva con Ansible listo.
"@ -ForegroundColor Gray
    }
}
