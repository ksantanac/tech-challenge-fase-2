#!/usr/bin/env bash
# Gera k8s/02-secret.yaml com os valores REAIS em base64.
# Uso: edite as variáveis abaixo com os endpoints/senhas dos seus RDS e rode:
#   bash k8s/generate-secret.sh > k8s/02-secret.yaml
set -euo pipefail

# ---- PREENCHA COM SEUS VALORES REAIS ----
AUTH_DB_URL="postgres://auth_user:SUA_SENHA@SEU_AUTH_RDS_ENDPOINT:5432/auth_db"
FLAG_DB_URL="postgres://flags_user:SUA_SENHA@SEU_FLAGS_RDS_ENDPOINT:5432/flags_db"
TARGETING_DB_URL="postgres://targeting_user:SUA_SENHA@SEU_TARGETING_RDS_ENDPOINT:5432/targeting_db"
MASTER_KEY="togglemaster-master-key-prod"
SERVICE_API_KEY="dev-service-key-local-12345"
# -----------------------------------------

b64() { printf '%s' "$1" | base64 -w0; }

cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: togglemaster-secrets
  namespace: togglemaster
type: Opaque
data:
  AUTH_DATABASE_URL: $(b64 "$AUTH_DB_URL")
  FLAG_DATABASE_URL: $(b64 "$FLAG_DB_URL")
  TARGETING_DATABASE_URL: $(b64 "$TARGETING_DB_URL")
  MASTER_KEY: $(b64 "$MASTER_KEY")
  SERVICE_API_KEY: $(b64 "$SERVICE_API_KEY")
EOF
