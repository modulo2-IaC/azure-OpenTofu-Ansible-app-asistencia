# Cadena de Suministro de Infraestructura como Código (Terraform / OpenTofu) en DevSecOps

> **De código a infraestructura segura, confiable y automatizada.**

---

## 1. Desarrollo

**Objetivo:** escribir el código Terraform / OpenTofu aplicando estándares de calidad, seguridad y consistencia desde la estación de trabajo.

**Archivos y directorios habituales**

- `.tf` (definición de recursos y arquitectura)
- `.tfvars` (parámetros por entorno)
- `.tflint.hcl` (reglas de análisis estático)
- `.terraform.lock.hcl` (bloqueo determinista de dependencias)
- `cloud-init-*.yaml` (especificaciones declarativas `#cloud-config`)
- `modules/` o `plantillas/` (modularización de componentes)

**Prácticas y herramientas**

- IDEs y extensiones con autocompletado y validación de esquema
- Inyección declarativa de archivos locales con `filebase64()` y `templatefile()`
- Pre-commit hooks y linters de secretos (Gitleaks, Secretlint)
- Formateo y validación temprana: `tofu fmt` / `tofu validate`

---

## 2. Control de versión

**Objetivo:** almacenar, auditar y revisar los cambios del código en un repositorio centralizado y protegido.

**Plataformas**

- GitHub
- GitLab
- Azure Repos

**Mecanismos de colaboración**

- Ramas de características (*Feature branches*) y rama protegida (`main`)
- Pull Requests / Merge Requests con plantillas estructuradas
- Asignación obligatoria de revisores (`CODEOWNERS`)

**Políticas**

- Revisión de código por pares (*Peer review*)
- Verificación de firmas criptográficas en commits
- Bloqueo de commits directos a `main`
- Requerimiento de escaneos y pipelines en verde antes de fusionar

---

## 3. Módulos y dependencias

**Objetivo:** modularizar, reutilizar código, reducir el acoplamiento y controlar dependencias externas.

**Componentes**

- Terraform / OpenTofu Registry
- Módulos internos y externos
- Proveedores y restricciones de versión estricta (*version constraints*)

### Principios de Diseño en IaC (DevSecOps): Alta Cohesión y Bajo Acoplamiento

1. **Alta Cohesión Interna (High Cohesion):**
   - Cada subsistema organiza sus recursos por archivos de dominio con responsabilidad única:
     - `red.tf`: Recursos de red (VNet, subredes, IP pública, NIC).
     - `seguridad.tf`: Políticas perimetrales, firewalls (NSG), reglas de puertos y generación de secretos (`jwt_secret`).
     - `backend.tf`: Cómputo de negocio (VM Linux, disco OS, Cloud-Init e inyección de `package.json` en base64).
     - `frontend.tf`: Servidor web de presentación (VM Linux, Nginx, SPA y Cloud-Init).
     - `monitoreo.tf`: Log Analytics Workspace, Action Groups y alertas métricas de CPU.
   - **Beneficio:** Facilita auditorías DevSecOps atómicas (por ejemplo, Checkov enfocado en `seguridad.tf` sin mezclar cómputo), y cada recurso tiene una única razón para cambiar.

2. **Bajo Acoplamiento Externo (Low Coupling):**
   - **Micro-estados remotos:** Separación de estados `.tfstate` independientes (`bootstrap` e `infra`) para reducir el radio de impacto (*blast radius*) y evitar bloqueos de concurrencia innecesarios.
   - **Interfaces declarativas:** Comunicación desacoplada entre componentes (Backend expone endpoints y su IP pública dinámicamente, y Frontend los consume como parámetros de entrada sin acoplamiento estático).

3. **Aprovisionamiento Declarativo de Cómputo (Cloud-Init + Systemd):**
   - **Inyección con `filebase64` y `write_files`:** OpenTofu lee los manifiestos de la aplicación (`package.json`, `index.html`) con `filebase64()` y los transfiere a las plantillas Cloud-Init, garantizando una entrega limpia y reproducible sin transferencias SSH intermedias.
   - **Servicios Nativos de Sistema Operativo:** En lugar de wrappers frágiles o gestores de procesos no nativos, se definen unidades de servicio nativas de `systemd` (`[Unit]`, `[Service]`, `[Install]`) en `/etc/systemd/system/`, garantizando arranque automático, supervisión del demonio y ciclo de vida estándar.

---

## 4. Gestión de secretos

**Objetivo:** gestionar credenciales y variables sensibles minimizando su exposición.

**Herramientas y servicios**

- Azure Key Vault
- AWS Secrets Manager
- HashiCorp Vault
- Generadores criptográficos seguros (`random_password`)

**Controles DevSecOps**

- **Cero secretos en código:** Marcado estricto de variables como `sensitive = true`.
- **Aislamiento de variables de entorno en el SO:** Archivos `.env` creados por Cloud-Init con permisos `permissions: "0600"` y propiedad restringida, evitando que usuarios no privilegiados o comandos `ps` del sistema accedan a cadenas de conexión de base de datos o firmas JWT.
- **Rotación y caducidad:** Mecanismos de rotación periódica de credenciales.

---

## 5. Análisis estático de código

**Objetivo:** mejorar la calidad y aplicar buenas prácticas al código IaC antes de su ejecución.

| Herramienta | Función indicada en el flujo DevSecOps |
|---|---|
| **TFLint** | Detección de errores y mejores prácticas con ruleset específico de AzureRM |
| **Terraform/OpenTofu Validate** | Validación formal de sintaxis y tipos de datos nativos |
| **Terraform Docs** | Generación automatizada de documentación de módulos |
| **Checkov** | Evaluación de políticas de seguridad estática sobre recursos IaC |
| **tfsec** | Análisis de vulnerabilidades y configuraciones inseguras |
| **Terrascan** | Verificación de cumplimiento contra estándares CIS |

---

## 6. Escaneo de secretos

**Objetivo:** detectar tokens, credenciales y claves privadas antes de que queden expuestos en el historial de Git.

| Herramienta | Función indicada en el flujo DevSecOps |
|---|---|
| **Gitleaks** | Detección de secretos mediante expresiones regulares y reglas de entropía |
| **TruffleHog** | Escaneo profundo de ramas y commits históricos |
| **detect-secrets** | Prevención en pre-commit de cadenas con alto riesgo |
| **GitGuardian** | Monitoreo continuo y alertas de exposición en repositorios |

**Elementos a proteger:**
- Llaves privadas SSH, API Keys y tokens de servicio
- Contraseñas de bases de datos y credenciales de Azure
- Secretos JWT y cadenas de conexión

---

## 7. Políticas y cumplimiento (Policy as Code)

**Objetivo:** evaluar y forzar el cumplimiento de políticas técnicas, regulatorias y de costes antes del despliegue.

| Herramienta | Función indicada en el flujo DevSecOps |
|---|---|
| **OPA / Conftest** | Evaluación de políticas declarativas en lenguaje Rego |
| **Sentinel / tfpolicy** | Gobierno y reglas de negocio sobre el plan de infraestructura |
| **Checkov (compliance)** | Verificación contra estándares CIS Azure Foundations, NIST e ISO 27001 |
| **KICS** | Escaneo avanzado de infraestructura y contenedores |
| **Infracost** | Estimación y control preventivo de costes cloud |

---

## 8. Plan de Terraform / OpenTofu

**Objetivo:** obtener una vista previa determinista de los cambios antes de su ejecución en la nube.

**Comando principal**

```bash
tofu plan -var-file="parametros/infra.tfvars" -out=tfplan
```

**Revisiones**

- Detección precisa de recursos a crear, modificar o destruir (*Drift analysis*)
- Análisis del radio de impacto de cambios destructivos
- Exportación del plan en formato JSON para evaluación de políticas automatizadas con OPA/Conftest

---

## 9. Aprobaciones (Security Gate)

**Objetivo:** gobernar y autorizar los cambios antes del aprovisionamiento en entornos productivos.

**Controles de gobernanza**

- Revisión manual obligatoria sobre el artefacto `tfplan`
- Aprobaciones escalonadas según el entorno (Dev -> Staging -> Prod)
- Matriz de separación de funciones (SoD)
- Puerta de control (*Security Gate*): Bloqueo automático si los escáneres de seguridad reportan vulnerabilidades críticas

---

## 10. Aplicación

**Objetivo:** desplegar de forma segura y consistente la infraestructura aprobada.

**Comando principal**

```bash
tofu apply -auto-approve tfplan
```

**Controles de aplicación**

- **Aprovisionamiento sin intervención (*Zero-Touch Provisioning*):** La combinación de OpenTofu y Cloud-Init (`write_files` + `runcmd`) entrega la infraestructura con la aplicación web compilada, migraciones ejecutadas y servicios activos desde el primer `tofu apply`.
- **Estado remoto cifrado y bloqueado:** Almacenamiento en Azure Blob Storage con cifrado en reposo y arrendamiento exclusivo (*lease blob*) para prevenir concurrencia.
- **Workspaces o parámetros por entorno:** Aislamiento de variables mediante `parametros/*.tfvars`.

---

## 11. Operación, infraestructura y monitoreo

**Objetivo:** operar la infraestructura desplegada, garantizar resiliencia y detectar desviaciones en tiempo real.

**Actividades**

- **Resiliencia con Systemd:** Servicios configurados con directivas `Restart=always` y aislamiento de usuario (`User=asistenciaapp`), reiniciándose automáticamente ante caídas sin requerir agentes pesados externos.
- **Detección de desviaciones (*Drift detection*):** Ejecución programada de `tofu plan -detailed-exitcode` para alertar sobre modificaciones manuales fuera del código IaC.
- **Logs y métricas consolidadas:** Ingesta de métricas del sistema operativo y logs en Azure Log Analytics Workspace.
- **Alertas preventivas:** Monitoreo activo de consumo de CPU (>80%) con notificaciones a través de Action Groups.

---

## Flujo Integral de la Cadena de Suministro

```text
[1. Código Fuente / Cloud-Init]
            │
            ▼
[2. Control de Versiones Git]
            │
            ▼
[3. Módulos & Restricciones]
            │
            ▼
[4. Parámetros & Secretos Protegidos]
            │
            ▼
[5. Análisis Estático (TFLint / Validate)]
            │
            ▼
[6. Escaneo de Secretos (Gitleaks)]
            │
            ▼
[7. Políticas como Código (Checkov / OPA)]
            │
            ▼
[8. Plan Determinista (tofu plan)]
            │
            ▼
[9. Puerta de Aprobación (Security Gate)]
            │
            ▼
[10. Despliegue Automatizado (tofu apply + Cloud-Init)]
            │
            ▼
[11. Operación, Systemd & Azure Monitor]
            │
            └──► (Retroalimentación continua hacia el desarrollo)
```
