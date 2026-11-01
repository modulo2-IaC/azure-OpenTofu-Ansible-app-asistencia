# Sistema de Asistencia — OpenTofu (Microsoft Azure)

Infraestructura como Código (IaC) en **Microsoft Azure** diseñada bajo principios de **Alta Cohesión y Bajo Acoplamiento** para desplegar el **Backend NestJS** y **Frontend React/Vite/Nginx** en máquinas virtuales Linux Ubuntu optimizadas para la capa gratuita (Azure Free Trial, región `swedencentral`).

---

## 📁 Estructura del Repositorio

El proyecto se organiza en dos subproyectos desacoplados:

1. **`bootstrap/`**: Inicialización del Storage Account y Blob Container en Azure para persistir el estado remoto (`.tfstate`).
2. **`infra/`**: Proyecto integral de aprovisionamiento de la **App Asistencia** (Backend + Frontend), con estructura inspirada en `recursos-app-asistencia`.

```text
hardware/
├── README.md                            # Documentación general del repositorio
├── IaC.md                               # Guía de los 11 Principios DevSecOps
├── .gitignore                           # Exclusiones de Git
├── .tflint.hcl                          # Configuración de linter estático con ruleset AzureRM
├── .gitleaks.toml                       # Reglas de detección y prevención de secretos
├── .github/
│   ├── workflows/
│   │   └── deploy.yml                   # CI/CD: Pipeline de validación y despliegue en GitHub Actions
│   ├── CODEOWNERS                       # Asignación de revisores obligatorios
│   ├── dependabot.yml                   # Mantenimiento automático de dependencias
│   └── pull_request_template.md         # Plantilla con checklist de revisión DevSecOps
├── bootstrap/                           # Subproyecto 1: Almacenamiento de estado remoto (.tfstate)
│   ├── main.tf                          # Resource Group para tfstate
│   ├── storage.tf                       # Storage Account y Blob Container
│   ├── variables.tf                     # Variables de entrada de bootstrap
│   ├── outputs.tf                       # Configuración de backend exportada
│   ├── versions.tf                      # Restricciones de proveedores
│   └── README.md                        # Documentación específica de bootstrap
└── infra/                               # Subproyecto 2: Aprovisionamiento de la App Asistencia
    ├── README.md                        # Documentación detallada del proyecto infra
    ├── ARQUITECTURA.md                  # Diagramas visuales, matrices de relación y flujo de red
    ├── .gitignore                       # Exclusiones de Git para infra
    ├── plantillas/                      # Plantillas modulares OpenTofu
    │   ├── main.tf                      # Orquestador raíz (Resource Group, tags y sufijo)
    │   ├── red.tf                       # VNet (10.0.0.0/16), Subredes, IPs públicas y NICs
    │   ├── seguridad.tf                 # Firewalls perimetrales (NSGs) y JWT Secret
    │   ├── backend.tf                   # Máquina Virtual Backend (NestJS + PM2)
    │   ├── frontend.tf                  # Máquina Virtual Frontend (React/Vite + Nginx)
    │   ├── monitoreo.tf                 # Log Analytics Workspace, Action Group y alertas CPU
    │   ├── cloud-init-backend.yaml      # Script de arranque: Node.js 20, PM2, compilación y seeds
    │   ├── cloud-init-frontend.yaml     # Script de arranque: Nginx Reverse Proxy, build Vite y SPA
    │   ├── variables.tf                 # Definición tipada de parámetros de entrada
    │   ├── outputs.tf                   # Salidas consolidadas (URLs, FQDNs, IPs y credenciales)
    │   └── versions.tf                  # Configuración de OpenTofu y backend azurerm
    ├── parametros/                      # Separación de parámetros por responsabilidad
    │   ├── infra.tfvars                 # Parámetros de red, región, acceso SSH y alertas
    │   ├── backend.tfvars               # Parámetros de DB Neon, JWT, CORS y repo backend
    │   ├── frontend.tfvars              # Parámetros del repositorio frontend y API URL
    │   └── *.example.tfvars             # Plantillas de ejemplo para versionado seguro
    ├── scripts/                         # Automatización de pruebas, despliegue y destrucción
    │   ├── deploy.ps1                   # Despliegue en Windows (PowerShell) con auto-bootstrap
    │   ├── deploy.sh                    # Despliegue en Linux/macOS (Bash)
    │   ├── destroy.ps1                  # Eliminación segura en Windows (PowerShell)
    │   └── destroy.sh                   # Eliminación segura en Linux/macOS (Bash)
    ├── reportes/                        # Auditoría DevSecOps y análisis de código
    │   ├── tofu-validate.md             # Validación de sintaxis nativa de OpenTofu
    │   ├── tflint.md                    # Análisis estático de esquema AzureRM
    │   ├── checkov.md                   # Escaneo de seguridad y cumplimiento CIS Azure
    │   └── README.md                    # Resumen ejecutivo de auditorías
    └── politicas/                       # Gobierno y protección de infraestructura
        └── proteccion-recursos.md       # Resource Locks y meta-argumento prevent_destroy
```

---

## 🚀 Despliegue Rápido de la App Asistencia

### Opción 1: Automatizado desde `infra/` (Recomendado)
El script `scripts\deploy.ps1` detecta si el Storage Account de `bootstrap` existe en Azure; si no existe, lo crea automáticamente antes de aplicar `plantillas`:

```powershell
cd "d:\soe\modulos\DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)\apps\app4\IAC\azure\OpenTofu\hardware\infra"

# Ejecutar despliegue completo
powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1
```

---

### Opción 2: Despliegue Manual con OpenTofu CLI

```powershell
# 1. Aprovisionar Storage Account de estado remoto (si no existe):
cd "d:\soe\modulos\DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)\apps\app4\IAC\azure\OpenTofu\hardware\bootstrap"
tofu init
tofu apply -auto-approve

# 2. Aprovisionar la App Asistencia:
cd "..\infra\plantillas"
tofu init
tofu plan `
  -var-file="../parametros/infra.tfvars" `
  -var-file="../parametros/backend.tfvars" `
  -var-file="../parametros/frontend.tfvars" `
  -out=tfplan

tofu apply -auto-approve tfplan
```

---

## 🗑️ Destrucción Controlada (Teardown)

Para eliminar los recursos de la App Asistencia en Azure y evitar cobros:

```powershell
cd "d:\soe\modulos\DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)\apps\app4\IAC\azure\OpenTofu\hardware\infra"
powershell -ExecutionPolicy Bypass -File scripts\destroy.ps1
```
