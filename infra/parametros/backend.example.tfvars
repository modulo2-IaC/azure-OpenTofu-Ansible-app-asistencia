# =============================================================================
# EJEMPLO DE PARÁMETROS: BACKEND NESTJS (backend.example.tfvars)
# =============================================================================

backend_vm_size = "Standard_B2s_v2"

admin_registration_no  = "123456789"
admin_initial_password = "123456789"
admin_full_name        = "ADMIN"

node_version = "20"

backend_repo_url    = "https://github.com/modulo2-IaC/app-asistencia-backend.git"
backend_repo_branch = "dev"

# Base de datos PostgreSQL en Azure (VM dedicada)
database_vm_size = "Standard_B2s_v2"
db_name          = "asistencia_db"
db_username      = "asistencia_user"
# db_password    = "" # Si está vacío, OpenTofu genera una contraseña segura automáticamente
# database_url   = "" # Si está vacío, OpenTofu construye la URL hacia la IP privada de la VM en Azure

jwt_secret   = ""

cors_origin    = "*"
app_timezone   = "America/La_Paz"
run_migrations = true
