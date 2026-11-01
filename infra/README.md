# Aprovisionamiento de Infraestructura: Sistema de Control de Asistencia (Azure con OpenTofu)

Este directorio contiene todo el código, plantillas modulares, parámetros por entorno, políticas de protección, reportes de calidad DevSecOps y scripts de automatización para aprovisionar el **Sistema de Control de Asistencia** en **Microsoft Azure** utilizando **OpenTofu**.

> 📊 **Guía Visual de Arquitectura:** Para consultar diagramas interactivos de red, topologías, flujo de datos y matrices de recursos, revisa el documento [ARQUITECTURA.md](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/ARQUITECTURA.md).

---

## 📁 Estructura del Proyecto `infra/` (Estilo Recursos-App-Asistencia)

```text
infra/
├── README.md                            # Documentación integral de este proyecto de aprovisionamiento
├── ARQUITECTURA.md                      # Diagramas visuales, matrices de relación y flujo de red
├── .gitignore                           # Exclusión de archivos de estado y variables con secretos
├── plantillas/                          # Arquitectura Modular OpenTofu (Alta Cohesión / Bajo Acoplamiento)
│   ├── main.tf                          # Orquestador raíz (Resource Group, tags globales y sufijo aleatorio)
│   ├── red.tf                           # Red Virtual (10.0.0.0/16), subredes backend/frontend, IPs públicas y NICs
│   ├── seguridad.tf                     # Firewalls perimetrales (NSGs), asociaciones y JWT Secret
│   ├── backend.tf                       # Máquina Virtual Backend Linux (NestJS + PM2)
│   ├── frontend.tf                      # Máquina Virtual Frontend Linux (React/Vite + Nginx)
│   ├── monitoreo.tf                     # Log Analytics Workspace, Action Group y alertas métricas de CPU
│   ├── cloud-init-backend.yaml          # Script de arranque Backend (rama dev, build, migraciones Neon y seeds)
│   ├── cloud-init-frontend.yaml         # Script de arranque Frontend (rama dev, Reverse Proxy y build Vite)
│   ├── variables.tf                     # Definición tipada de parámetros de entrada
│   ├── outputs.tf                       # Salidas consolidadas (URLs, FQDNs, IPs y credenciales)
│   └── versions.tf                      # Configuración de OpenTofu y backend "azurerm"
├── parametros/                          # Separación de parámetros por responsabilidad
│   ├── infra.tfvars                     # Parámetros de red, región, acceso SSH y alertas
│   ├── backend.tfvars                   # Parámetros de DB Neon, JWT, CORS y repo backend
│   ├── frontend.tfvars                  # Parámetros del repositorio frontend y API URL
│   └── *.example.tfvars                 # Plantillas de ejemplo para versionado seguro
├── scripts/                             # Automatización de pruebas, despliegue y destrucción
│   ├── deploy.ps1                       # Despliegue en Windows (PowerShell) con auto-bootstrap
│   ├── deploy.sh                        # Despliegue en Linux/macOS (Bash)
│   ├── destroy.ps1                      # Eliminación segura en Windows (PowerShell)
│   └── destroy.sh                       # Eliminación segura en Linux/macOS (Bash)
├── reportes/                            # Evidencias y auditoría DevSecOps
│   ├── tofu-validate.md                 # Reporte de validación oficial de OpenTofu (0 Errores)
│   ├── tflint.md                        # Reporte de linter con ruleset de AzureRM
│   ├── checkov.md                       # Reporte de seguridad CIS Azure y justificaciones Free Tier
│   └── README.md                        # Resumen ejecutivo de auditorías
└── politicas/                           # Gobierno y protección de infraestructura
    └── proteccion-recursos.md           # Resource Locks y meta-argumento prevent_destroy
```

---

## 🏛 Principios Arquitectónicos Aplicados

### 1. Alta Cohesión (Single Responsibility)
Cada archivo dentro de `plantillas/` agrupa exclusivamente los recursos de un dominio técnico específico:

| Módulo | Responsabilidad | Recursos Gestionados |
|---|---|---|
| [`main.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/main.tf) | Orquestación raíz y Resource Group | `azurerm_resource_group.rg`, `random_string.suffix`, tags globales |
| [`red.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/red.tf) | Topología y conectividad de red | VNet (`10.0.0.0/16`), Subred Backend (`10.0.1.0/24`), Subred Frontend (`10.0.2.0/24`), IPs Públicas Estáticas y NICs |
| [`seguridad.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/seguridad.tf) | Perímetro de firewall y secretos | NSGs (SSH 22, Web 80/443, NestJS 3000), asociaciones NIC-NSG y generación segura de `jwt_secret` |
| [`backend.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/backend.tf) | Servidor de aplicaciones de negocio | VM Linux Ubuntu 22.04 LTS (`Standard_B2s_v2`), disco OS 30GB, Cloud-Init (Node 20, NestJS, PM2, migraciones DB) |
| [`frontend.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/frontend.tf) | Servidor web de presentación | VM Linux Ubuntu 22.04 LTS (`Standard_B2s_v2`), disco OS 30GB, Cloud-Init (Nginx Reverse Proxy, build de Vite/React) |
| [`monitoreo.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/plantillas/monitoreo.tf) | Salud, auditoría y alertas operativas | Log Analytics Workspace (retención 30 días), Action Group (Email SRE), alarmas de CPU > 80% |

### 2. Bajo Acoplamiento (Loose Coupling)
- **Resolución directa en memoria:** El frontend recibe dinámicamente la IP pública del backend (`azurerm_public_ip.pip_backend.ip_address`), eliminando la necesidad de consultas de estado cruzado estáticas.
- **Separación de Parámetros:** Los parámetros se dividen por contexto en `parametros/` (`infra.tfvars`, `backend.tfvars`, `frontend.tfvars`).

---

## 🚀 Métodos de Despliegue

### Método 1: Despliegue Automatizado con Script (Recomendado)
El script [`scripts/deploy.ps1`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/infra/scripts/deploy.ps1) gestiona todo el ciclo de vida:
- Verifica los archivos en `parametros/`.
- Comprueba si el módulo `../../bootstrap` ya creó el Storage Account en Azure; si no existe, lo crea automáticamente.
- Valida y formatea las plantillas.
- Inicializa OpenTofu y aplica la infraestructura.
- Imprime la tabla de resumen con URLs y credenciales.

```powershell
cd "d:\soe\modulos\DCID-V1E1 - 02 I INFRAESTRUCTURA COMO CÓDIGO (IAC)\apps\app4\IAC\azure\OpenTofu\hardware\infra"

# Ejecutar despliegue completo
powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1
```

> [!TIP]
> **Modos opcionales:**
> - Simulación sin crear recursos: `powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1 -DryRun`
> - Omitir escaneos DevSecOps: `powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1 -SkipScan`

---

### Método 2: Despliegue Manual con OpenTofu CLI

```powershell
# 1. Asegurar que el Storage Account de bootstrap exista:
cd "..\bootstrap"
tofu init
tofu apply -auto-approve
cd "..\infra\plantillas"

# 2. Inicializar y aplicar plantillas principales:
tofu init
tofu plan `
  -var-file="../parametros/infra.tfvars" `
  -var-file="../parametros/backend.tfvars" `
  -var-file="../parametros/frontend.tfvars" `
  -out=tfplan

tofu apply -auto-approve tfplan
```

---

## 🔑 Credenciales y Accesos Predeterminados

Una vez concluido el despliegue:
- **Frontend Web:** Ingresa en tu navegador a la URL de `frontend_url` (o `frontend_ip_url`).
- **Swagger Docs:** `http://<IP_BACKEND>:3000/api/docs`.

| Rol | Matrícula / Registro | Contraseña |
|---|:---:|:---:|
| **Administrador** | `123456789` | `123456789` |
| **Estudiante Demo** | `12345600` | `12345600` |

---

## 🗑️ Destrucción Controlada (Teardown)

Para eliminar todos los recursos y evitar consumo de créditos de Azure:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\destroy.ps1
```
O manualmente:
```powershell
cd plantillas
tofu destroy -auto-approve `
  -var-file="../parametros/infra.tfvars" `
  -var-file="../parametros/backend.tfvars" `
  -var-file="../parametros/frontend.tfvars"
```

