#!/usr/bin/env bash
set -euo pipefail
# aws-install.sh — AWS CLI v2.
# Two seams: install (composable, unattended) and configure (interactive,
# opt-in). The orchestrator only ever calls install; configure blocks on
# credentials, so it stays behind `aws-install.sh configure`.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_aws_cli() {
  if have aws; then
    ark_log "aws cli: present ($(aws --version 2>&1)) — skipping"
    return 0
  fi
  ark_log "installing aws cli v2"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${tmp}/awscliv2.zip"
  unzip -q "${tmp}/awscliv2.zip" -d "${tmp}"
  sudo "${tmp}/aws/install" --update
  rm -rf "${tmp}"
  aws --version
}

# Interactive — prompts for credentials. Not called by the orchestrator.
#   AWS Access Key ID     [None]: ...
#   AWS Secret Access Key [None]: ...
#   Default region name   [None]: us-west-1   # make sure it is us-west-1
#   Default output format [None]:             # leave blank
configure_aws() {
  have aws || { ark_err "aws cli not installed — run install first."; return 1; }
  aws configure
}

main() {
  case "${1:-install}" in
    install)   install_aws_cli ;;
    configure) configure_aws ;;
    *) ark_err "usage: aws-install.sh [install|configure]"; return 2 ;;
  esac
}

main "$@"
