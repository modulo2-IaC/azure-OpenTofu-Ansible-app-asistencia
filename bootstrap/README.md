# Bootstrap: Azure Blob Storage para OpenTofu Remote State

Este módulo aprovisiona los recursos mínimos y necesarios en Azure para almacenar el estado remoto (`.tfstate`) de OpenTofu tanto para el **backend** como para el **frontend** de forma segura, centralizada y compatible con el **plan gratuito de Azure**.

---

## 🏛 Recursos Creados

1. **Azure Resource Group**: `rg-asistencia-tfstate` (ubicación: `swedencentral`).
2. **Azure Storage Account**: `sttofuasistenciadev` (SKU: `Standard_LRS`, TLS 1.2, acceso público deshabilitado, versionado de blobs habilitado para recuperación ante desastres).
3. **Azure Blob Container**: `tfstate` (acceso privado).

---

## 📁 Estructura del Módulo (Alta Cohesión)

```text
bootstrap/
├── main.tf          # Orquestación del módulo, etiquetas y Resource Group
├── storage.tf       # Dominio de almacenamiento: Storage Account y Blob Container
├── variables.tf     # Parámetros de entrada configurables
├── outputs.tf       # Salidas y bloques de backend recomendados
└── versions.tf      # Proveedores requeridos y versiones mínimas
```

---

## 🚀 Despliegue Rápido

### Prerrequisitos
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) instalado y autenticado (`az login`).
- [OpenTofu](https://opentofu.org/) v1.6 o superior (`tofu version`).

### Comandos de Ejecución

```bash
# 1. Inicializar OpenTofu
tofu init

# 2. Previsualizar cambios
tofu plan

# 3. Aplicar infraestructura
tofu apply -auto-approve
```

---

## 🔗 Llaves de Estado Remoto Configuradas

| Componente | Archivo de Estado en Blob Storage |
|------------|-----------------------------------|
| **Infraestructura Unificada (Backend + Frontend)** | `infra.terraform.tfstate` |

El proyecto `infra/` consume este almacenamiento a través del bloque `backend "azurerm"` configurado en `versions.tf`.

---

## 📦 Instrucciones para Subir a un Repositorio GitHub Independiente

Para mantener este código en su propio repositorio de GitHub:

```bash
# 1. Inicializar repositorio git local (si aún no lo está)
git init

# 2. Agregar origen remoto
git remote add origin https://github.com/modulo2-IaC/azure-OpenTofu-bootstrap-frontend-y-backend.git

# 3. Verificar que .gitignore proteja los archivos sensibles
git status
# Asegúrate de que NO aparezcan archivos .tfstate ni credenciales

# 4. Crear commit inicial
git add .
git commit -m "feat(iac): initial OpenTofu remote state bootstrap for Azure"

# 5. Subir a GitHub
git branch -M main
git push -u origin main
```
