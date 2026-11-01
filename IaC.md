# Cadena de Suministro de Infraestructura como Código (Terraform) en DevSecOps

> **De código a infraestructura segura y confiable.**

## 1. Desarrollo

**Objetivo:** escribir el código Terraform.

**Archivos y directorios habituales**

- `.tf`
- `.tfvars`
- `.tflint.hcl`
- `.terraform.lock.hcl`
- `modules/`

**Prácticas y herramientas**

- IDEs
- Pre-commit hooks
- `terraform fmt` / `terraform validate`

## 2. Control de versión

**Objetivo:** almacenar y revisar los cambios del código en un repositorio.

**Plataformas**

- GitHub
- GitLab
- Azure Repos

**Mecanismos de colaboración**

- Branches
- Pull Requests
- Code owners

**Políticas**

- Revisión de código
- Firmas de commits
- Protección de ramas
- Requerimiento de Pull Request (PR)

## 3. Módulos y dependencias

**Objetivo:** modularizar, reutilizar código, reducir el acoplamiento y controlar dependencias.

**Componentes**

- Terraform / OpenTofu Registry
- Módulos internos y externos
- Proveedores y restricciones de versión (*version constraints*)

**Principios de Diseño en IaC (DevSecOps): Alta Cohesión y Bajo Acoplamiento**

1. **Alta Cohesión Interna (High Cohesion):**
   - Cada subsistema organiza sus recursos por archivos de dominio con responsabilidad única:
     - `network.tf`: Recursos de red (VNet, subredes, IP pública, NIC).
     - `security.tf`: Políticas perimetrales, firewalls (NSG), reglas de puertos y secretos.
     - `compute.tf`: Cómputo (VMs, discos OS, imágenes y Cloud-Init).
     - `storage.tf`: Cuentas de almacenamiento de objetos/blobs.
     - `monitoring.tf`: Log Analytics, Action Groups y alertas métricas.
   - Beneficio: Facilita auditorías DevSecOps atómicas (por ejemplo, Checkov/TFLint enfocados en `security.tf` sin mezclar lógica de cómputo), y cada recurso tiene una única razón para cambiar.

2. **Bajo Acoplamiento Externo (Low Coupling):**
   - **Micro-estados remotos:** Separación de archivos de estado `.tfstate` independientes (`bootstrap`, `backend`, `frontend`) en lugar de un monolito de estado. Esto reduce el radio de impacto (*blast radius*) ante incidentes y evita bloqueos de concurrencia innecesarios.
   - **Interfaces declarativas:** Comunicación desacoplada entre componentes (Backend expone endpoints en `outputs.tf`, Frontend los consume como variables de entrada `vite_api_url` sin dependencias duras de estado).

**Validaciones**

- Versionado de módulos y restricciones estrictas (`~> 3.100`)
- Dependencias permitidas
- Evitar módulos no confiables

## 4. Gestión de secretos

**Objetivo:** gestionar credenciales y variables sensibles.

**Herramientas y servicios**

- Azure Key Vault
- AWS Secrets Manager
- HashiCorp Vault

**Controles**

- No guardar secretos en el código
- Usar variables sensibles
- Preferir credenciales temporales
- Rotar los secretos

## 5. Análisis estático de código

**Objetivo:** mejorar la calidad y aplicar buenas prácticas al código IaC.

| Herramienta | Función indicada en la imagen |
|---|---|
| **TFLint** | Reglas de Terraform |
| **Terraform Validate** | Validación de sintaxis |
| **Terraform Docs** | Documentación |
| **Checkov** | Políticas de seguridad IaC |
| **tfsec** | Análisis de seguridad |
| **Terrascan** | Cumplimiento y políticas |

## 6. Escaneo de secretos

**Objetivo:** detectar datos sensibles antes de que queden expuestos.

| Herramienta | Función indicada en la imagen |
|---|---|
| **Gitleaks** | Secretos en código |
| **TruffleHog** | Detección de credenciales |
| **detect-secrets** | Patrones de secretos |
| **GitGuardian** | Monitoreo de secretos |

**Evitar exponer**

- Keys, tokens y passwords
- Credenciales de proveedores
- Información sensible

## 7. Políticas y cumplimiento

**Objetivo:** evaluar políticas técnicas y organizacionales.

| Herramienta | Función indicada en la imagen |
|---|---|
| **OPA / Conftest** | Políticas Rego |
| **tfpolicy / Sentinel** | Políticas organizacionales |
| **Checkov (compliance)** | CIS, NIST e ISO |
| **KICS** | Escaneo IaC avanzado |
| **Infracost (opcional)** | Estimación de costos |

**Controles de cumplimiento**

- Políticas de la organización
- Estándares (CIS, NIST, ISO)
- Bloqueo de cambios inseguros

## 8. Plan de Terraform

**Objetivo:** obtener una vista previa de los cambios antes de aplicarlos.

**Comando principal**

```bash
terraform plan
```

**Revisiones**

- Detección de cambios
- Revisión de recursos
- Análisis de impactos
- Políticas sobre el plan

**Herramientas y formatos**

- OPA (plan JSON)
- Infracost (costos)
- SARIF para reportes

## 9. Aprobaciones

**Objetivo:** gobernar y autorizar los cambios antes del despliegue.

**Controles de gobernanza**

- Revisión manual
- Aprobaciones según entorno
- Separación de funciones
- Reglas de negocio
- Evidencia y trazabilidad

**Puerta de control de seguridad (*security gate*)**

- Todos los escáneres en verde
- Políticas cumplidas
- Aprobadores requeridos
- Registro de auditoría

## 10. Aplicación

**Objetivo:** desplegar la infraestructura aprobada.

**Comando principal**

```bash
terraform apply
```

**Controles de aplicación**

- Despliegue automatizado
- Backends remotos
- Estado (*state*) cifrado y bloqueado
- Workspaces por entorno

**Ejemplos de backends**

- Azure Storage
- AWS S3 + DynamoDB
- Terraform Cloud
- Google Cloud Storage

## 11. Infraestructura y monitoreo

**Objetivo:** operar la infraestructura desplegada y detectar cambios o anomalías.

**Plataformas de nube representadas**

- AWS
- Microsoft Azure
- Google Cloud

**Actividades**

- Seguimiento de recursos desplegados
- Detección de desviaciones (*drift detection*)
- Logs y métricas
- Alertas y seguridad
- Cumplimiento continuo

**Herramientas**

- Azure Monitor / CloudWatch
- Grafana / Prometheus
- SIEM (Sentinel / Security Hub)

---

## Flujo principal de la cadena

1. Código fuente
2. Repositorio Git
3. Módulos / proveedores
4. Variables y secretos
5. Código validado
6. Reporte de escaneos
7. Plan aprobado
8. Ejecución
9. Infraestructura desplegada

El diagrama también muestra un ciclo de **retroalimentación continua**: corregir, mejorar y aprender. La retroalimentación vuelve desde la infraestructura desplegada hacia el desarrollo para iterar sobre el código y los controles.

## Controles transversales de seguridad

Estos controles actúan a lo largo de la cadena de suministro, no en una sola etapa.

| Control | Alcance y ejemplos de la imagen |
|---|---|
| **Gestión de identidades y accesos** | IAM, RBAC, SSO |
| **Seguridad de proveedores** | Restricciones de versión y firmas |
| **Escaneo continuo de dependencias** | Trivy, Snyk, Dependabot |
| **Políticas como código** | OPA, Sentinel, Conftest |
| **Gestión de estado** | Cifrado, bloqueo y versionado |
| **Auditoría y trazabilidad** | Logs, reportes y SIEM |
| **Monitoreo continuo** | Alertas, drift y anomalías |
