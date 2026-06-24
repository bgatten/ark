#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_docker() {
  if have docker && id -nG "$USER" | grep -qw docker; then
    ark_log "docker: present and $USER in docker group — skipping"
    return 0
  fi

  ark_platform
  add_apt_repo docker \
    https://download.docker.com/linux/ubuntu/gpg \
    "https://download.docker.com/linux/ubuntu ${ARK_CODENAME} stable"

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # add docker local user permissions
  sudo usermod -aG docker "$USER"
  ark_request_reboot "docker group membership for $USER (takes effect after re-login)"

  # verify (best effort — group membership not yet live this session)
  sudo docker run hello-world || ark_warn "docker hello-world failed — daemon not ready yet?"
}

install_docker
