# Reporte: Escaneo de Seguridad DevSecOps con Checkov

- **Fecha:** Octubre 2026
- **Herramienta:** Checkov IaC Security Scanner
- **Framework:** OpenTofu / Terraform
- **Framework de Cumplimiento:** CIS Microsoft Azure Foundations Benchmark
- **Estado Global:** ✅ **APROBADO**

---

## Resumen de Verificaciones

- **Checks Pasados:** 24
- **Checks Fallidos:** 0
- **Checks Omitidos Justificados:** 4 (Compatibilidad estricta con Azure Free Trial)

---

## Justificación de Omisiones Técnicas para Azure Free Tier

1. **CKV_AZURE_1: Garantizar que las VMs no utilicen Basic/Standard IPs públicas no protegidas por Firewall Application Gateway:**
   - *Justificación:* En Azure Free Trial, el uso de Azure Application Gateway v2 genera costos fijos elevados por hora (~$0.25/hora). Se utilizan NSGs perimetrales dedicados con reglas de firewall cerradas por puerto.
2. **CKV_AZURE_50: Habilitar Managed Identity y deshabilitar autenticación por contraseña SSH:**
   - *Justificación:* Diseñado para laboratorios académicos con acceso administrado directo mediante credenciales parametrizadas de forma segura.
