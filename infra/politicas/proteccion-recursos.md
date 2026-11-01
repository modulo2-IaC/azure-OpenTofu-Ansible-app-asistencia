# Política de Protección de Recursos en Microsoft Azure

Este documento establece las directrices de gobernanza para evitar la eliminación accidental de recursos críticos, retener registros de auditoría y aplicar el principio de mínimo privilegio en el **Sistema de Asistencia**.

---

## 1. Bloqueos de Recursos en Azure (Resource Locks)

Para entornos de producción o persistencia extendida, se deben aplicar bloqueos de tipo `CanNotDelete` sobre el Resource Group principal o el Storage Account del estado remoto:

```bash
# Bloquear eliminación accidental del Resource Group de estado remoto (bootstrap)
az lock create \
  --name "Lock-Evitar-Borrado-TFState" \
  --resource-group "rg-asistencia-tfstate" \
  --lock-type CanNotDelete \
  --notes "Protege el Storage Account con el estado remoto infra.terraform.tfstate"
```

---

## 2. Protección en el Ciclo de Vida de OpenTofu (prevent_destroy)

En el código de infraestructura, recursos irremplazables deben protegerse con la meta-propiedad `lifecycle`:

```hcl
lifecycle {
  prevent_destroy = true
}
```

*Recursos protegidos recomendados:*
- Storage Account de `.tfstate` (`bootstrap/storage.tf`).
- Log Analytics Workspace (`plantillas/monitoreo.tf`).

---

## 3. Retención de Auditoría y Telemetría

- **Log Analytics Workspace:** Los logs de actividad y telemetría de las máquinas virtuales se retienen durante **30 días** (`retention_in_days = 30`) sin costo adicional en el tier estándar de Azure Monitor.

---

## 4. Recursos Externos Excluidos de IaC (Data-Only)

Los siguientes componentes viven fuera del ciclo de vida de este proyecto y **nunca** deben aprovisionarse ni eliminarse desde OpenTofu:

| Recurso | Proveedor / Servicio | Gestión |
|---|---|---|
| **Base de Datos PostgreSQL** | Neon Serverless Cloud | Neon Dashboard / Migraciones Prisma/TypeORM |
| **Repositorios Git** | GitHub (`app-asistencia-*`) | GitHub Web / Git CLI |
