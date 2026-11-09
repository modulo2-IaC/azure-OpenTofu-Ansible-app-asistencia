#!/usr/bin/env bash
# =============================================================================
# Lanzador de Ansible mediante contenedor Docker
# Compatible con Git Bash, Linux y macOS
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARDWARE_DIR="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$HARDWARE_DIR/ansible"

ACTION="${1:-help}"
shift || true
EXTRA_ARGS="$*"

# Validar Docker
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker no está en ejecución. Por favor inicia Docker Desktop."
    exit 1
fi

IMAGE_NAME="asistencia-ansible:latest"
if ! docker images -q "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Construyendo imagen local '$IMAGE_NAME'..."
    docker build -t "$IMAGE_NAME" "$ANSIBLE_DIR"
fi

SSH_VOLUME=""
if [ -d "$HOME/.ssh" ]; then
    SSH_VOLUME="-v $HOME/.ssh:/root/.ssh_host:ro"
fi

TTY_FLAG=""
if [ -t 0 ] && [ -t 1 ]; then
    TTY_FLAG="-t"
fi

DOCKER_BASE="docker run --rm -i $TTY_FLAG -v \"$ANSIBLE_DIR:/ansible\" $SSH_VOLUME -e ANSIBLE_HOST_KEY_CHECKING=False -w /ansible $IMAGE_NAME"

case "$ACTION" in
    syntax)
        echo ">>> [TEST 1] Verificando sintaxis de playbooks..."
        eval "$DOCKER_BASE ansible-playbook -i inventory/hosts.ini playbooks/site.yml --syntax-check $EXTRA_ARGS"
        ;;
    ping)
        echo ">>> [TEST 2] Probando conectividad con hosts..."
        eval "$DOCKER_BASE ansible all -i inventory/hosts.ini -m ping $EXTRA_ARGS"
        ;;
    check)
        echo ">>> [TEST 3] Modo simulación (--check --diff)..."
        eval "$DOCKER_BASE ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check --diff $EXTRA_ARGS"
        ;;
    deploy)
        echo ">>> [DESPLIEGUE] Aplicando playbooks en Azure..."
        eval "$DOCKER_BASE ansible-playbook -i inventory/hosts.ini playbooks/site.yml $EXTRA_ARGS"
        ;;
    backend)
        echo ">>> [BACKEND] Aprovisionando Backend..."
        eval "$DOCKER_BASE ansible-playbook -i inventory/hosts.ini playbooks/backend.yml $EXTRA_ARGS"
        ;;
    frontend)
        echo ">>> [FRONTEND] Aprovisionando Frontend..."
        eval "$DOCKER_BASE ansible-playbook -i inventory/hosts.ini playbooks/frontend.yml $EXTRA_ARGS"
        ;;
    bash)
        echo ">>> Abriendo consola Bash en el contenedor..."
        eval "docker run --rm -it -v \"$ANSIBLE_DIR:/ansible\" $SSH_VOLUME -e ANSIBLE_HOST_KEY_CHECKING=False -w /ansible $IMAGE_NAME /bin/bash"
        ;;
    *)
        cat << 'EOF'
Uso: ./scripts/run-ansible.sh [syntax|ping|check|deploy|backend|frontend|bash] [argumentos-extra]
EOF
        ;;
esac
