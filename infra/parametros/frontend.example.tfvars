# =============================================================================
# EJEMPLO DE PARÁMETROS: FRONTEND REACT + VITE + NGINX (frontend.example.tfvars)
# =============================================================================

# Standard_F1as_v7 = 1 vCPU / 4 GB RAM (Optimizado para cuota regional de 4 vCPUs)
frontend_vm_size = "Standard_F1as_v7"

frontend_repo_url    = "https://github.com/modulo2-IaC/app-asistencia-frontend.git"
frontend_repo_branch = "dev"

vite_api_url = "/api/v1/"
