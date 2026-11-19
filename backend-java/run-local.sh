#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "${script_dir}/.." && pwd)"

cd "${project_root}"
if [[ ! -f .env ]]; then
  echo "Arquivo ${project_root}/.env nao encontrado. Use .env.example como referencia." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
if [[ -f .env.local ]]; then
  # shellcheck disable=SC1091
  source .env.local
fi
set +a

export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-local}"
exec backend-java/mvnw -f backend-java/pom.xml spring-boot:run
