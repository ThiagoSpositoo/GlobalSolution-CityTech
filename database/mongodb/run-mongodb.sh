#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/../.." && pwd)"

for script in 01-schema.js 02-seed.js 03-queries.js 04-tests.js; do
  printf 'Executando database/mongodb/%s\n' "${script}"
  docker compose --project-directory "${project_dir}" exec -T mongodb sh -lc \
    'exec mongosh --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --file /dev/stdin' \
    < "${script_dir}/${script}"
done
