#!/usr/bin/env bash
# =============================================================================
# Aplica o schema (init.sql) em cada RDS PostgreSQL usando um container postgres
# (não precisa instalar psql na máquina — usa o Docker que você já tem).
# Requer que os RDS estejam com "Public access = Yes" e o Security Group liberando
# a porta 5432 para o seu IP.
#
# PREENCHA os endpoints e senhas abaixo antes de rodar:  bash aws/03-migrations.sh
# =============================================================================
set -euo pipefail

# ---- PREENCHA ----
AUTH_HOST="SEU_AUTH_RDS_ENDPOINT";        AUTH_PASS="SUA_SENHA_AUTH"
FLAG_HOST="SEU_FLAGS_RDS_ENDPOINT";       FLAG_PASS="SUA_SENHA_FLAGS"
TARGETING_HOST="SEU_TARGETING_RDS_ENDPOINT"; TARGETING_PASS="SUA_SENHA_TARGETING"
# ------------------

run_sql() {
  local host="$1" user="$2" pass="$3" db="$4" sqldir="$5"
  echo ">> Aplicando schema em ${db} (${host})..."
  for f in "$sqldir"/*.sql; do
    echo "   - $(basename "$f")"
    docker run --rm -e PGPASSWORD="$pass" -v "$(pwd)/$sqldir":/sql postgres:15-alpine \
      psql -h "$host" -U "$user" -d "$db" -f "/sql/$(basename "$f")"
  done
}

run_sql "$AUTH_HOST"      auth_user      "$AUTH_PASS"      auth_db      auth-service/db
run_sql "$FLAG_HOST"      flags_user     "$FLAG_PASS"      flags_db     flag-service/db
run_sql "$TARGETING_HOST" targeting_user "$TARGETING_PASS" targeting_db targeting-service/db

echo ""
echo ">> Schemas aplicados. O auth_db já vem com a chave de serviço de dev semeada"
echo "   (seed-dev-key.sql), então o evaluation-service consegue chamar flag/targeting."
