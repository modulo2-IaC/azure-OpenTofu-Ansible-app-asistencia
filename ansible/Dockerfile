FROM alpine:3.19

# Instalar Ansible, cliente OpenSSH, git y dependencias
RUN apk update && \
    apk add --no-cache \
    ansible \
    ansible-lint \
    openssh-client \
    python3 \
    py3-pip \
    curl \
    git \
    bash \
    rsync \
    ca-certificates

# Variables de entorno por defecto
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV PYTHONUNBUFFERED=1

WORKDIR /ansible

# Script de entrada para corrección de permisos de claves SSH (0600)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ansible", "--version"]
