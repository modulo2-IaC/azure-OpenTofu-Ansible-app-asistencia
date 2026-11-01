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

database_url = "postgresql://usuario:contrasena@tu-host.neon.tech/neondb?sslmode=require"
jwt_secret   = ""

cors_origin    = "*"
app_timezone   = "America/La_Paz"
run_migrations = true
