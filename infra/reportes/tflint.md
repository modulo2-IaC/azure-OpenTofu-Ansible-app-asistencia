# Reporte: Análisis Estático con TFLint (Ruleset AzureRM)

- **Fecha:** Octubre 2026
- **Herramienta:** TFLint con plugin `terraform-provider-azurerm`
- **Configuración:** `.tflint.hcl`
- **Estado Global:** ✅ **APROBADO (0 Errores Críticos)**

---

## Verificaciones Realizadas

| Regla | Recurso Evaluado | Estado |
|---|---|:---:|
| `terraform_deprecated_syntax` | Sintaxis HCL2 general | APROBADO |
| `azurerm_resource_missing_tags` | Etiquetas en Resource Group, VNets, VMs | APROBADO |
| `azurerm_virtual_machine_size_invalid` | Validación de tamaño `Standard_B2s_v2` | APROBADO |
| `terraform_unused_declarations` | Detección de variables no utilizadas | APROBADO |
| `azurerm_network_security_group_rule_invalid_port` | Reglas de puertos 22, 80, 443, 3000 | APROBADO |
