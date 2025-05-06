#!/bin/bash

# Usage: source source_cuda.sh <version>
# Example: source source_cuda.sh 12.2

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "❌ Please source this script: 'source source_cuda.sh <version>'"
  exit 1
fi

CUDA_DIR="/usr/local"
CUDA_VERSION="$1"

if [[ -z "$CUDA_VERSION" ]]; then
  echo "Usage: source source_cuda.sh <version>"
  echo "Available cuda versions:"
  ls -d ${CUDA_DIR}/cuda-* 2>/dev/null | grep -oP 'cuda-\K[0-9.]+'
  return 1
fi

if [[ ! -d "${CUDA_DIR}/cuda-${CUDA_VERSION}" ]]; then
  echo "❌ CUDA version ${CUDA_VERSION} not found in ${CUDA_DIR}"
  return 1
fi

export CUDA_HOME="${CUDA_DIR}/cuda-${CUDA_VERSION}"
export PATH="${CUDA_HOME}/bin:$PATH"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:$LD_LIBRARY_PATH"

echo "✅ Now using CUDA ${CUDA_VERSION}"

# Copy this to your .bashrc
# _cuda_versions() {
#   local cur="${COMP_WORDS[COMP_CWORD]}"
#   COMPREPLY=( $(compgen -W "$(ls -d /usr/local/cuda-* 2>/dev/null | grep -oP 'cuda-\K[0-9.]+')" -- "$cur") )
# }
# complete -F _cuda_versions source_cuda.sh