# Guía Visual de Arquitectura — Sistema de Asistencia (Azure con OpenTofu)

Este documento detalla la arquitectura de infraestructura como código (IaC) desplegada en **Microsoft Azure** mediante **OpenTofu**, ilustrando la topología de red, seguridad perimetral, interacción entre Backend y Frontend, y el flujo de despliegue automatizado.

---

## 1. Diagrama General de Arquitectura en Azure

```mermaid
graph TD
    subgraph Internet["🌐 Internet Pública"]
        Users["👥 Usuarios Web (Navegador)"]
        Admin["💻 Administrador (DevOps / SSH :22)"]
        NeonDB[("🐘 PostgreSQL Neon DB (Cloud)\nPuerto 5432 con SSL")]
        GitBack["🐙 Repositorio Git Backend\napp-asistencia-backend.git (rama dev)"]
        GitFront["🐙 Repositorio Git Frontend\napp-asistencia-frontend.git (rama dev)"]
    end

    subgraph Azure_Cloud["☁️ Microsoft Azure — Region swedencentral"]
        subgraph RG["Resource Group: rg-asistencia-dev-*"]
            subgraph VNet["VNet: vnet-asistencia-dev (10.0.0.0/16)"]

                subgraph SubnetFront["Subred Frontend (10.0.2.0/24)"]
                    PIP_Front["📌 IP Pública Estática Frontend\n(Standard SKU + FQDN)"]
                    NSG_Front["🛡️ NSG Frontend\nIn: 80 (HTTP), 443 (HTTPS), 22 (SSH)"]
                    VM_Front["🖥️ VM Frontend: vm-asistencia-front-dev-*\nUbuntu 22.04 LTS (Standard_B2s_v2)\nNginx Web Server + Vite React Build"]
                end

                subgraph SubnetBack["Subred Backend (10.0.1.0/24)"]
                    PIP_Back["📌 IP Pública Estática Backend\n(Standard SKU + FQDN)"]
                    NSG_Back["🛡️ NSG Backend\nIn: 3000 (API NestJS), 22 (SSH)"]
                    VM_Back["🖥️ VM Backend: vm-asistencia-back-dev-*\nUbuntu 22.04 LTS (Standard_B2s_v2)\nNode.js 20 + PM2 + NestJS API"]
                end

            end

            subgraph Observability["📈 Observabilidad y Alertas (Azure Monitor)"]
                LAW["📁 Log Analytics Workspace (30 días)"]
                AG["📢 Action Group: ag-alerts (Email SRE)"]
                Alert_Back["⏰ Alerta CPU Backend > 80% (5m)"]
                Alert_Front["⏰ Alerta CPU Frontend > 80% (5m)"]
            end
        end

        subgraph StateRemote["📦 Estado Remoto OpenTofu (bootstrap/)"]
            RG_State["rg-asistencia-tfstate"]
            ST_State["Storage Account: sttofuasistenciadev"]
            Blob_State["Container: tfstate / infra.terraform.tfstate"]
        end
    end

    Users -->|HTTP :80 / HTTPS :443| PIP_Front
    Admin -->|SSH :22| PIP_Front
    Admin -->|SSH :22| PIP_Back
    PIP_Front --> VM_Front
    PIP_Back --> VM_Back

    VM_Front -->|Proxy Inverso /api/ -> :3000/api/| PIP_Back
    VM_Back -->|SSL :5432| NeonDB

    GitFront -.->|git clone en boot| VM_Front
    GitBack -.->|git clone en boot| VM_Back

    VM_Back -.-> Alert_Back
    VM_Front -.-> Alert_Front
    Alert_Back & Alert_Front --> AG
```

---

## 2. Matriz de Módulos (Alta Cohesión / Bajo Acoplamiento)

Cada archivo en `plantillas/` agrupa exclusivamente los recursos de un dominio técnico específico:

| Archivo de Plantilla | Responsabilidad Única | Recursos Gestionados |
|---|---|---|
| [`main.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/plantillas/main.tf) | Orquestación raíz y Resource Group | `azurerm_resource_group.rg`, `random_string.suffix`, tags globales |
| [`red.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/plantillas/red.tf) | Topología y conectividad de red | `azurerm_virtual_network`, subredes backend/frontend, IPs públicas estáticas y NICs |
| [`seguridad.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/plantillas/seguridad.tf) | Perímetro de firewall y secretos | `azurerm_network_security_group` (backend y frontend), asociaciones NIC-NSG, `jwt_secret` |
| [`backend.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/plantillas/backend.tf) | Servidor de aplicaciones de negocio | `azurerm_linux_virtual_machine.backend_vm`, disco OS 30GB, cloud-init (Node 20, NestJS, PM2) |
| [`frontend.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/plantillas/frontend.tf) | Servidor web de presentación | `azurerm_linux_virtual_machine.frontend_vm`, disco OS 30GB, cloud-init (Nginx, React/Vite build) |
| [`monitoreo.tf`](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/plantillas/monitoreo.tf) | Salud operativa y alertas | `azurerm_log_analytics_workspace`, `azurerm_monitor_action_group`, alertas métricas CPU > 80% |

---

## 3. Flujo de Arranque Automatizado con Cloud-Init

```mermaid
sequenceDiagram
    autonumber
    actor DevOps as Ingeniero DevOps
    participant Tofu as OpenTofu Engine
    participant Azure as Microsoft Azure API
    participant VM_B as VM Backend (Ubuntu 22)
    participant VM_F as VM Frontend (Ubuntu 22)
    participant DB as Neon PostgreSQL

    DevOps->>Tofu: tofu apply -var-file=...
    Tofu->>Azure: Crear VNet, Subredes, NSGs e IPs Públicas
    Tofu->>Azure: Crear VM Backend con cloud-init
    Azure->>VM_B: Iniciar VM Backend
    Note over VM_B: 1. Swap 1GB<br/>2. Instalar Node.js 20 & PM2<br/>3. Clonar rama dev backend<br/>4. Generar .env<br/>5. npm install && npm run build<br/>6. Migraciones TypeORM y Semillas<br/>7. Iniciar servicio PM2 :3000
    VM_B->>DB: Migraciones & Seeds (Admin / Estudiante)
    Tofu->>Azure: Crear VM Frontend (recibe IP Backend)
    Azure->>VM_F: Iniciar VM Frontend
    Note over VM_F: 1. Swap 1GB<br/>2. Instalar Nginx & Node.js 20<br/>3. Configurar Reverse Proxy Nginx :80 -> Backend:3000<br/>4. Clonar rama dev frontend<br/>5. npm install && npm run build (Vite)<br/>6. Reload Nginx
    DevOps-->>VM_F: Acceso inmediato vía navegador web (HTTP :80)
```
