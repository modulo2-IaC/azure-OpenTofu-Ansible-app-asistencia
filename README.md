# Sistema de Asistencia — OpenTofu + Ansible (Microsoft Azure)

Infraestructura como Código (IaC) y Gestión de Configuración en **Microsoft Azure** diseñada bajo principios de **Alta Cohesión y Bajo Acoplamiento** para desplegar el **Backend NestJS** y **Frontend React/Vite/Nginx** en máquinas virtuales Linux Ubuntu optimizadas para la capa gratuita (Azure Free Trial, región `swedencentral`).

- **OpenTofu**: Aprovisiona la infraestructura cloud base (VNet, Subredes, IPs públicas, NSGs, NICs y Máquinas Virtuales) y exporta dinámicamente las IPs al inventario de Ansible.
- **Ansible**: Gestiona la configuración del sistema operativo, memoria swap, dependencias (Node.js 20, Nginx), clonación de código, compilación, variables de entorno protegidas (`0600`), migraciones TypeORM, semillas y servicios nativos de **Systemd**.

---

## 📁 Estructura del Repositorio

El proyecto se organiza en tres subsistemas desacoplados:

1. **`bootstrap/`**: Inicialización del Storage Account y Blob Container en Azure para persistir el estado remoto (`.tfstate`).
2. **`infra/`**: Aprovisionamiento de infraestructura cloud con **OpenTofu**.
3. **`ansible/`**: Gestión de configuración, despliegue de software y orquestación con **Ansible** (incluye soporte para Docker en Windows).

```text
hardware/
├── README.md                            # Documentación general del repositorio
├── IaC.md                               # Guía de los 11 Principios DevSecOps
├── scripts/                             # Scripts ejecutables centralizados de automatización
│   ├── deploy.ps1                       # Despliegue unificado (OpenTofu + Ansible) en PowerShell
│   ├── deploy.sh                        # Despliegue unificado en Bash / Git Bash
│   ├── run-ansible.ps1                  # Lanzador de Ansible vía Docker en PowerShell
│   ├── run-ansible.sh                   # Lanzador de Ansible vía Docker en Bash
│   ├── destroy.ps1                      # Destrucción de infraestructura en PowerShell
│   └── destroy.sh                       # Destrucción de infraestructura en Bash
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
    │   ├── backend.tf                   # VM Backend (NestJS + Systemd, autenticación SSH)
    │   ├── frontend.tf                  # VM Frontend (React/Vite + Nginx + Systemd, autenticación SSH)
    │   ├── monitoreo.tf                 # Log Analytics Workspace, Action Group y alertas CPU
    │   ├── ansible_inventory.tf         # Generador dinámico de inventario para Ansible
    │   ├── variables.tf                 # Definición tipada de parámetros de entrada
    │   ├── outputs.tf                   # Salidas consolidadas (URLs, FQDNs, IPs y credenciales)
    │   └── versions.tf                  # Configuración de OpenTofu y backend azurerm
    ├── parametros/                      # Separación de parámetros por responsabilidad
    │   ├── infra.tfvars                 # Parámetros de red, región, acceso SSH y alertas
    │   ├── backend.tfvars               # Parámetros de DB Neon, JWT, CORS y repo backend
    │   ├── frontend.tfvars              # Parámetros del repositorio frontend y API URL
    │   └── *.example.tfvars             # Plantillas de ejemplo para versionado seguro
    ├── reportes/                        # Auditoría DevSecOps y análisis de código
    │   ├── tofu-validate.md             # Validación de sintaxis nativa de OpenTofu
    │   ├── tflint.md                    # Análisis estático de esquema AzureRM
    │   ├── checkov.md                   # Escaneo de seguridad y cumplimiento CIS Azure
    │   └── README.md                    # Resumen ejecutivo de auditorías
    └── politicas/                       # Gobierno y protección de infraestructura
        └── proteccion-recursos.md       # Resource Locks y meta-argumento prevent_destroy
└── ansible/                             # Subproyecto 3: Gestión de Configuración y Despliegue
    ├── README.md                        # Guía de ejecución, pruebas y comandos rápidos
    ├── Dockerfile                       # Entorno reproducible de Ansible para Windows
    ├── docker-compose.yml               # Orquestador Docker de Ansible
    ├── entrypoint.sh                    # Entrypoint Docker: gestiona permisos SSH (0600)
    ├── ansible.cfg                      # Configuración de Ansible y parámetros de conexión
    ├── inventory/                       # Inventario de servidores
    │   ├── hosts.ini                    # Generado dinámicamente por OpenTofu (ignorado en Git)
    │   ├── hosts.example.ini            # Plantilla de referencia
    │   └── group_vars/                  # Variables agrupadas (all, backend, frontend)
    └── playbooks/                       # Playbooks de aprovisionamiento y despliegue
        ├── site.yml                     # Playbook maestro (Backend + Frontend)
        ├── backend.yml                  # Playbook autónomo para el Backend (Swap, Node.js, NestJS, Systemd)
        ├── frontend.yml                 # Playbook autónomo para el Frontend (Swap, Node.js, Nginx, Vite)
        ├── ping.yml                     # Playbook de prueba de conectividad
        └── templates/                   # Plantillas Jinja2 consolidadas
            ├── asistencia-backend.env.j2
            ├── asistencia-backend.service.j2
            ├── asistencia-frontend.env.j2
            └── nginx-asistencia.conf.j2
```

---

## ⚙️ Arquitectura Desacoplada: OpenTofu + Ansible

1. **OpenTofu (`infra/`)**: Aprovisiona la infraestructura base en Azure (VNet, Subredes, IPs públicas, NSGs, NICs y Máquinas Virtuales Ubuntu puras). Utiliza autenticación exclusiva por par de claves SSH (`asistencia_vm`) y exporta dinámicamente las IPs públicas hacia [`ansible/inventory/hosts.ini`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu-Ansible/hardware/ansible/inventory/hosts.ini).
2. **Ansible (`ansible/`)**: Toma el control del sistema operativo mediante playbooks autónomos e integrados (`backend.yml` y `frontend.yml`) para configurar memoria Swap, instalar Node.js 20 LTS, clonar repositorios, inyectar variables de entorno protegidas (`0600`), compilar proyectos, ejecutar migraciones y levantar servicios con Systemd y Nginx.

---

## 🚀 Ejecución desde la Raíz del Proyecto (`hardware/`)

Todos los comandos se ejecutan directamente desde el directorio raíz:
* **PowerShell**: `cd "d:\soe\modulos\DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)\apps\app4\IAC\azure\OpenTofu-Ansible\hardware"`
* **Git Bash**: `cd "/d/soe/modulos/DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)/apps/app4/IAC/azure/OpenTofu-Ansible/hardware"`

### 1. Despliegue Completo (OpenTofu + Ansible con 1 solo comando)

Aprovisiona la infraestructura en Azure y despliega todo el software automáticamente:

**PowerShell:**
```powershell
.\scripts\deploy.ps1
```

**Git Bash / Linux:**
```bash
./scripts/deploy.sh
```

---

### 2. Flujo Granular Paso a Paso

Si prefieres ejecutar cada fase de manera independiente:

#### Fase A: Aprovisionar Infraestructura Cloud (OpenTofu)
```powershell
# PowerShell
.\scripts\deploy.ps1 -Target infra

# Git Bash
./scripts/deploy.sh infra
```
*Esto crea las VMs y actualiza automáticamente `ansible/inventory/hosts.ini`.*

#### Fase B: Pruebas y Despliegue con Ansible (vía Docker)

```powershell
# 1. Validar sintaxis de playbooks (sin tocar servidores)
.\scripts\run-ansible.ps1 syntax

# 2. Comprobar conectividad SSH con Azure
.\scripts\run-ansible.ps1 ping

# 3. Simulación Dry-Run (previsualizar cambios sin ejecutarlos)
.\scripts\run-ansible.ps1 check

# 4. Desplegar configuración y aplicaciones (Backend + Frontend)
.\scripts\run-ansible.ps1 deploy

# 5. Desplegar un solo componente
.\scripts\run-ansible.ps1 backend
.\scripts\run-ansible.ps1 frontend

# 6. Abrir terminal interactiva dentro del contenedor
.\scripts\run-ansible.ps1 bash
```

*(En Git Bash, utiliza `./scripts/run-ansible.sh <accion>`, por ejemplo `./scripts/run-ansible.sh ping`)*

---

### 3. Validación de Idempotencia

Vuelve a ejecutar el comando de despliegue:
```powershell
.\scripts\run-ansible.ps1 deploy
```
*Si la configuración es idempotente, todas las tareas reportarán estado `ok` con `changed=0`.*

---

## 🗑️ Destrucción Controlada de Recursos (Teardown)

Para eliminar todos los recursos creados en Microsoft Azure y evitar costos:

**PowerShell:**
```powershell
.\scripts\destroy.ps1
```

**Git Bash / Linux:**
```bash
./scripts/destroy.sh
```
