# Reportes de Calidad y Seguridad DevSecOps (OpenTofu en Azure)

Este directorio consolida los reportes generados por las herramientas de escaneo estático, linters de infraestructura y auditoría de seguridad para los módulos OpenTofu del **Sistema de Asistencia**.

---

## 📊 Resumen Ejecutivo de Resultados

| Herramienta | Tipo de Análisis | Alcance | Resultado | Reporte Detallado |
|---|---|---|:---:|---|
| **OpenTofu Validate** | Sintaxis, tipos de datos y dependencias internas | Todas las plantillas (`plantillas/*.tf`) | **0 Errores** (100% Válido) | [tofu-validate.md](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/reportes/tofu-validate.md) |
| **TFLint (AzureRM)** | Análisis estático y mejores prácticas para Azure | Módulos `red`, `seguridad`, `backend`, `frontend`, `monitoreo` | **Aprobado** (0 Errores) | [tflint.md](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/reportes/tflint.md) |
| **Checkov** | Seguridad DevSecOps y cumplimiento CIS Azure | Todos los recursos de infraestructura | **Aprobado** (Compatibilidad Free Tier) | [checkov.md](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/reportes/checkov.md) |

---

## 🔍 Detalle por Herramienta

### 1. [OpenTofu Validate](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/reportes/tofu-validate.md)
- Valida que todos los bloques de recursos, variables, referencias cruzadas y funciones HCL sean sintáctica y semánticamente correctos.
- **Resultado:** `Success! The configuration is valid.`

### 2. [TFLint](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/reportes/tflint.md)
- Aplica el ruleset oficial de Microsoft AzureRM para OpenTofu/Terraform.
- Verifica convenciones de nombres, tamaños de máquina virtual válidos (`Standard_B2s_v2`) y configuraciones de red.

### 3. [Checkov](file:///d:/soe/modulos/DCID-V1E1%20-%2002%20I%20INFRAESTRUCTURA%20COMO%20C%C3%93DIGO%20%28IAC%29/apps/app4/IAC/azure/OpenTofu/hardware/reportes/checkov.md)
- Escanea vulnerabilidades de seguridad perimetral, almacenamiento y cómputo.
- Las omisiones están técnicamente justificadas para operar en la capa de evaluación gratuita (Azure Free Trial).
