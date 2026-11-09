# Guía de Aprovisionamiento y Pruebas con Ansible

Esta carpeta contiene la implementación completa de **Ansible** para el aprovisionamiento de configuración y despliegue del sistema (Backend NestJS + Frontend React/Vite/Nginx) en máquinas virtuales Ubuntu de Azure aprovisionadas previamente por **OpenTofu**.

---

## 🏗️ Arquitectura OpenTofu + Ansible

| Capa | Herramienta | Responsabilidad |
|---|---|---|
| **Infraestructura Cloud ("Hardware")** | **OpenTofu** | Resource Groups, VNet, Subredes, IPs Públicas, NSGs (Firewalls) y Máquinas Virtuales Linux puras. Exporta automáticamente las IPs a `ansible/inventory/hosts.ini`. |
| **Configuración y Software** | **Ansible** | Memoria Swap, repositorio NodeSource (Node.js 20), Nginx, clonación Git, variables `.env` protegidas, compilación, migraciones TypeORM, semillas y servicios Systemd. |

---

## 🚀 Cómo ejecutar y probar en Windows (con Docker)

Dado que Ansible no corre nativamente en Windows, se incluye un entorno encapsulado en Docker (`Dockerfile` y `docker-compose.yml`) y un script interactivo para PowerShell (`run-ansible.ps1`).

### Requisito previo
1. Abrir **Docker Desktop** en Windows y verificar que el motor esté corriendo.

---

### Comandos de Pruebas Rápidas (PowerShell)

Desde la raíz `hardware/` del proyecto:

```powershell
cd "d:\soe\modulos\DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)\apps\app4\IAC\azure\OpenTofu-Ansible\hardware"

# 1. Validar sintaxis YAML de los playbooks (sin tocar servidores)
.\scripts\run-ansible.ps1 syntax

# 2. Probar conectividad SSH y disponibilidad de Python en las VMs de Azure
.\scripts\run-ansible.ps1 ping

# 3. Modo Simulación (Dry-Run): previsualizar cambios sin ejecutarlos
.\scripts\run-ansible.ps1 check

# 4. Desplegar toda la solución (Database + Backend + Frontend)
.\scripts\run-ansible.ps1 deploy

# 5. Desplegar únicamente un componente
.\scripts\run-ansible.ps1 database
.\scripts\run-ansible.ps1 backend
.\scripts\run-ansible.ps1 frontend

# 6. Abrir una consola interactiva dentro del contenedor de Ansible
.\scripts\run-ansible.ps1 bash
```

---

## 📁 Estructura de Directorios

```text
ansible/
├── Dockerfile                  # Imagen Docker con Ansible, OpenSSH y sshpass
├── docker-compose.yml          # Configuración de volúmenes y variables para Docker
├── entrypoint.sh               # Normalización de permisos SSH (0600) para Docker en Windows
├── ansible.cfg                 # Configuración de conexión, escalamiento sudo y callbacks
├── inventory/
│   ├── hosts.ini               # Inventario activo generado por OpenTofu (ignorado en Git)
│   ├── hosts.example.ini       # Plantilla de ejemplo
│   └── group_vars/
│       ├── all.yml             # Variables comunes (node_version, swap_size_gb, tz)
│       ├── database.yml        # Variables de PostgreSQL (usuario, base de datos, puerto)
│       ├── backend.yml         # Variables de NestJS, TypeORM y variables de entorno
│       └── frontend.yml        # Variables de Vite, Reverse Proxy y Nginx
└── playbooks/
    ├── site.yml                # Orquestador principal (ejecuta database + backend + frontend)
    ├── database.yml            # Playbook autónomo para PostgreSQL Server (10.0.3.0/24)
    ├── backend.yml             # Playbook autónomo para el Backend (Swap, Node.js, NestJS, Systemd)
    ├── frontend.yml            # Playbook autónomo para el Frontend (Swap, Node.js, Nginx, Vite)
    ├── ping.yml                # Playbook rápido de diagnóstico de red y SSH
    └── templates/              # Plantillas Jinja2 consolidadas
        ├── asistencia-backend.env.j2
        ├── asistencia-backend.service.j2
        ├── asistencia-frontend.env.j2
        └── nginx-asistencia.conf.j2
```

---

## 🔄 Flujo de Trabajo Integrado (OpenTofu -> Ansible)

1. **Aprovisionar Infraestructura**:
   ```powershell
   cd ..\infra\plantillas
   tofu init
   tofu apply -var-file="../parametros/infra.tfvars" -var-file="../parametros/backend.tfvars" -var-file="../parametros/frontend.tfvars" -auto-approve
   ```
   *Al finalizar, OpenTofu actualizará automáticamente el archivo `ansible/inventory/hosts.ini` con las nuevas IPs públicas.*

2. **Aprovisionar Aplicación con Ansible**:
   ```powershell
   cd ..\..
   .\scripts\run-ansible.ps1 ping
   .\scripts\run-ansible.ps1 deploy
   ```

3. **Verificación de Idempotencia**:
   * Ejecuta nuevamente `.\scripts\run-ansible.ps1 deploy`.
   * Todas las tareas deben reportar estado `ok` con `changed=0`, garantizando que el sistema es completamente idempotente y reproducible.

