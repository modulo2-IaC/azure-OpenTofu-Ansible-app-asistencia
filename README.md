# Sistema de Asistencia — OpenTofu + Ansible (Microsoft Azure)

Infraestructura como Código (IaC) y Gestión de Configuración en **Microsoft Azure** diseñada bajo arquitectura **3-Tier (Tres Capas)** y principios de **Alta Cohesión y Bajo Acoplamiento** para desplegar de forma autocontenida:
- **Capa de Datos**: Servidor de Base de Datos **PostgreSQL** en máquina virtual Linux dedicada y aislada en subred privada (`10.0.3.0/24`).
- **Capa de Aplicación**: API REST **NestJS** gestionada por **Systemd** en subred privada (`10.0.1.0/24`).
- **Capa Web**: Frontend **React/Vite** servido por **Nginx** como *Reverse Proxy* en subred (`10.0.2.0/24`).

Toda la solución está optimizada para la capa gratuita (Azure Free Trial, región `swedencentral`).

- **OpenTofu**: Aprovisiona la infraestructura cloud base (VNet, 3 Subredes, IPs públicas, NSGs con aislamiento perimetral, NICs y 3 Máquinas Virtuales) y exporta dinámicamente las IPs y credenciales al inventario de Ansible.
- **Ansible**: Gestiona la configuración del sistema operativo, memoria swap, dependencias (PostgreSQL, Node.js 20, Nginx), clonación de código, compilación, variables de entorno protegidas (`0600`), migraciones TypeORM, semillas y servicios nativos de **Systemd**.

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
    │   ├── red.tf                       # VNet (10.0.0.0/16), 3 Subredes, IPs públicas y NICs
    │   ├── seguridad.tf                 # Firewalls perimetrales (NSGs), JWT Secret y password DB
    │   ├── database.tf                  # VM Database (PostgreSQL Server, subred aislada 10.0.3.0/24)
    │   ├── backend.tf                   # VM Backend (NestJS + Systemd, autenticación SSH)
    │   ├── frontend.tf                  # VM Frontend (React/Vite + Nginx + Systemd, autenticación SSH)
    │   ├── monitoreo.tf                 # Log Analytics Workspace, Action Group y alertas CPU
    │   ├── ansible_inventory.tf         # Generador dinámico de inventario para Ansible (3-Tier)
    │   ├── variables.tf                 # Definición tipada de parámetros de entrada
    │   ├── outputs.tf                   # Salidas consolidadas (URLs, FQDNs, IPs y credenciales)
    │   └── versions.tf                  # Configuración de OpenTofu y backend azurerm
    ├── parametros/                      # Separación de parámetros por responsabilidad
    │   ├── infra.tfvars                 # Parámetros de red, región, acceso SSH y alertas
    │   ├── backend.tfvars               # Parámetros de VM DB PostgreSQL, JWT, CORS y repo backend
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
    │   └── group_vars/                  # Variables agrupadas (all, database, backend, frontend)
    │       ├── all.yml                  # Variables comunes (Swap, tz, paquetes)
    │       ├── database.yml             # Variables de PostgreSQL (usuario, base de datos, puerto)
    │       ├── backend.yml              # Variables de NestJS (rutas, puerto 3000, repo)
    │       └── frontend.yml             # Variables de Vite y Nginx (usuario www-data, repo)
    └── playbooks/                       # Playbooks de aprovisionamiento y despliegue
        ├── site.yml                     # Playbook maestro (Database + Backend + Frontend)
        ├── database.yml                 # Playbook autónomo para PostgreSQL Server (10.0.3.0/24)
        ├── backend.yml                  # Playbook autónomo para NestJS (Swap, Node.js, Systemd)
        ├── frontend.yml                 # Playbook autónomo para Frontend (Swap, Node.js, Nginx, Vite)
        ├── ping.yml                     # Playbook de prueba de conectividad
        └── templates/                   # Plantillas Jinja2 consolidadas
            ├── asistencia-backend.env.j2
            ├── asistencia-backend.service.j2
            ├── asistencia-frontend.env.j2
            └── nginx-asistencia.conf.j2
```

---

## ⚙️ Arquitectura Desacoplada: OpenTofu + Ansible (3-Tier)

1. **OpenTofu (`infra/`)**: Aprovisiona la infraestructura base en Azure (VNet `10.0.0.0/16`, 3 Subredes dedicadas, IPs públicas, NSGs con aislamiento perimetral, NICs y 3 Máquinas Virtuales Ubuntu puras). Utiliza autenticación exclusiva por par de claves SSH (`asistencia_vm`) y exporta dinámicamente las IPs públicas y privadas hacia [`ansible/inventory/hosts.ini`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu-Ansible/hardware/ansible/inventory/hosts.ini).
2. **Ansible (`ansible/`)**: Toma el control del sistema operativo mediante playbooks autónomos e integrados ejecutados en estricto orden de dependencias:
   - **`database.yml`**: Instala PostgreSQL, configura escucha en red privada (`listen_addresses = '*'`), reglas `pg_hba.conf` para la subred backend y crea la base de datos `asistencia_db` y usuario `asistencia_user`.
   - **`backend.yml`**: Configura memoria Swap, instala Node.js 20 LTS, clona la API NestJS, inyecta variables protegidas (`0600`) apuntando a la **IP privada de la VM Database** (`sslmode=disable`), compila, ejecuta migraciones TypeORM/seeds y levanta el servicio con Systemd.
   - **`frontend.yml`**: Instala Node.js 20 LTS y Nginx, clona el frontend, compila la SPA con Vite, configura el VirtualHost Reverse Proxy (`/api` -> Backend) y reinicia Nginx.

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

# 4. Desplegar configuración y aplicaciones (Database + Backend + Frontend)
.\scripts\run-ansible.ps1 deploy

# 5. Desplegar un solo componente
.\scripts\run-ansible.ps1 database
.\scripts\run-ansible.ps1 backend
.\scripts\run-ansible.ps1 frontend

# 6. Abrir terminal interactiva dentro del contenedor (ver sección detallada abajo)
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

## 💻 Ejecución de Comandos Ansible en la Terminal de Docker

Dado que Ansible no corre de forma nativa en el host Windows, se encuentra instalado y configurado dentro del contenedor Docker (`asistencia-ansible:latest`). Puedes abrir una **terminal interactiva `bash`** dentro de dicho contenedor para ejecutar comandos nativos de Ansible en tiempo real contra las máquinas virtuales de Azure.

### 1. Iniciar la Sesión Interactiva

Desde la raíz de `hardware/`:

**PowerShell:**
```powershell
.\scripts\run-ansible.ps1 bash
```

**Git Bash / Linux:**
```bash
./scripts/run-ansible.sh bash
```

> [!NOTE]
> Al iniciar la sesión, el script monta automáticamente el directorio `hardware/ansible/` en `/ansible` y tu carpeta `~/.ssh` con permisos Unix corregidos (`chmod 600`), dejándote en el prompt de Linux:
> ```bash
> root@<container-id>:/ansible#
> ```

---

### 2. Comandos que puedes ejecutar dentro del Contenedor

Una vez dentro de la terminal interactiva, puedes ejecutar cualquier comando oficial de Ansible:

#### A. Diagnóstico de Inventario y Conectividad
```bash
# Visualizar la jerarquía de grupos y servidores
ansible-inventory -i inventory/hosts.ini --graph

# Comprobar conectividad SSH y módulo Python en todas las VMs
ansible all -i inventory/hosts.ini -m ping

# Comprobar conectividad únicamente al grupo backend
ansible backend -i inventory/hosts.ini -m ping
```

#### B. Comandos Ad-Hoc en las VMs de Azure (sin tocar los playbooks)
```bash
# Consultar el estado del servicio NestJS en la VM Backend
ansible backend -i inventory/hosts.ini -m command -a "systemctl status asistencia-backend"

# Consultar el estado del servidor Nginx en la VM Frontend
ansible frontend -i inventory/hosts.ini -m command -a "systemctl status nginx"

# Validar la sintaxis de configuración de Nginx en vivo
ansible frontend -i inventory/hosts.ini -m command -a "nginx -t"

# Consultar consumo de memoria RAM y Swap en todas las máquinas
ansible all -i inventory/hosts.ini -m command -a "free -h"

# Verificar espacio en disco de las VMs
ansible all -i inventory/hosts.ini -m command -a "df -h /"

# Ver el tiempo de actividad (uptime) y carga del sistema
ansible all -i inventory/hosts.ini -m command -a "uptime"
```

#### C. Ejecución de Playbooks con Opciones Avanzadas
```bash
# Despliegue completo maestro (Backend + Frontend)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# Despliegue con modo verboso / depuración detallada (logs de fallos)
ansible-playbook -i inventory/hosts.ini playbooks/backend.yml -vvv

# Ejecución interactiva paso a paso (pide confirmación antes de cada tarea)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --step

# Modo Dry-Run (simulación sin aplicar cambios reales)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check --diff
```

---

### 3. Salir del Contenedor

Para finalizar la sesión interactiva:
```bash
exit
```
*Al salir, el contenedor se destruye automáticamente (`--rm`), manteniendo tu sistema host de Windows completamente limpio.*

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
