# Sistema de Asistencia — OpenTofu (Microsoft Azure)

Infraestructura como Código (IaC) en **Microsoft Azure** diseñada bajo principios de **Alta Cohesión y Bajo Acoplamiento** para desplegar el **Backend NestJS** y **Frontend React/Vite/Nginx** en máquinas virtuales Linux Ubuntu optimizadas para la capa gratuita (Azure Free Trial, región `swedencentral`).

El aprovisionamiento del software se realiza en el primer arranque mediante **Cloud-Init declarativo** con inyección de archivos en Base64 (`write_files`), variables de entorno protegidas (`0600`) y servicios nativos de **Systemd**.

---

## 📁 Estructura del Repositorio

El proyecto se organiza en dos subproyectos desacoplados:

1. **`bootstrap/`**: Inicialización del Storage Account y Blob Container en Azure para persistir el estado remoto (`.tfstate`).
2. **`infra/`**: Proyecto integral de aprovisionamiento de la **App Asistencia** (Backend + Frontend), con estructura inspirada en `recursos-app-asistencia`.

```text
hardware/
├── README.md                            # Documentación general del repositorio
├── IaC.md                               # Guía de los 11 Principios DevSecOps (incluye Cloud-Init declarativo y Systemd)
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
    │   ├── backend.tf                   # VM Backend (NestJS + Systemd, Cloud-Init declarativo write_files)
    │   ├── frontend.tf                  # VM Frontend (React/Vite + Nginx + Systemd, Cloud-Init write_files)
    │   ├── monitoreo.tf                 # Log Analytics Workspace, Action Group y alertas CPU
    │   ├── cloud-init-backend.yaml      # Cloud-Init conciso: write_files (package.json b64, .env 0600, service) + runcmd
    │   ├── cloud-init-frontend.yaml     # Cloud-Init conciso: write_files (package.json b64, index.html b64, Nginx) + runcmd
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

## ⚙️ Aprovisionamiento Automatizado: Cloud-Init Declarativo y Systemd

Tanto el Backend como el Frontend se aprovisionan de forma completamente automatizada en el primer arranque de las máquinas virtuales Linux, utilizando la sintaxis estándar de **Cloud-Init** (`write_files` + `runcmd`) y servicios nativos de **Systemd**.

### 1. Inyección de Manifiestos con `filebase64` en OpenTofu
En las plantillas [`backend.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/backend.tf) y [`frontend.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/frontend.tf), los archivos de la aplicación (`package.json`, `index.html`) se cargan y codifican en Base64 para inyectarse de forma segura en las plantillas YAML:

```hcl
locals {
  carpeta_app_backend = "${path.module}/../../../../asistencia-backend"
  backend_package_json = fileexists("${local.carpeta_app_backend}/package.json") ? filebase64("${local.carpeta_app_backend}/package.json") : base64encode("...")
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  ...
  custom_data = base64encode(templatefile("${path.module}/cloud-init-backend.yaml", {
    package_json = local.backend_package_json
    ambiente     = var.environment
    ...
  }))
}
```

### 2. Estructura Declarativa `#cloud-config`
Los archivos [`cloud-init-backend.yaml`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/cloud-init-backend.yaml) y [`cloud-init-frontend.yaml`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/cloud-init-frontend.yaml) implementan una configuración corta, limpia y funcional:

* **`write_files`**:
  * **Archivos de aplicación**: decodificados automáticamente en destino (`encoding: b64`).
  * **Variables de entorno (`.env`)**: permisos estrictos `permissions: "0600"` para proteger credenciales y secretos de base de datos.
  * **Unidades de servicio Systemd**: `/etc/systemd/system/asistencia-backend.service` y `/etc/systemd/system/asistencia-frontend.service`.
* **`runcmd`**:
  * **Memoria Swap (1GB)**: previene errores *Out-Of-Memory* (OOM) durante la compilación de TypeScript y Vite en instancias con recursos ajustados.
  * **Sincronización de código**: clona el código fuente desde la rama `dev` del repositorio oficial.
  * **Compilación y ciclo de vida**: ejecuta `npm install`, `npm run build`, migraciones TypeORM (`migration:run`) y semillas (`seed:admin`, `seed:student`).
  * **Usuario de servicio**: creación del usuario del sistema sin shell (`asistenciaapp`) y asignación de permisos de propiedad.
  * **Inicio del servicio**: `systemctl daemon-reload` y `systemctl enable --now <servicio>`.

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
