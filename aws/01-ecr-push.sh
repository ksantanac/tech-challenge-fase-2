#!/usr/bin/env bash
# =============================================================================
# Cria os 5 repositórios no ECR e publica as imagens Docker.
# Pré-requisitos: aws CLI configurada (aws configure) + Docker rodando.
# Rode a partir da RAIZ do projeto:  bash aws/01-ecr-push.sh
# =============================================================================
set -euo pipefail

REGION="us-east-1"
SERVICES=(auth-service flag-service targeting-service evaluation-service analytics-service)

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo ">> Conta AWS: ${ACCOUNT_ID}"
echo ">> Registry:  ${REGISTRY}"

echo ">> Fazendo login no ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

for svc in "${SERVICES[@]}"; do
  echo ">> [$svc] criando repositório (ignora se já existe)..."
  aws ecr create-repository --repository-name "$svc" --region "$REGION" >/dev/null 2>&1 || true

  echo ">> [$svc] build + tag + push..."
  docker build -t "$svc:latest" "./$svc"
  docker tag "$svc:latest" "${REGISTRY}/${svc}:latest"
  docker push "${REGISTRY}/${svc}:latest"
  echo ">> [$svc] OK -> ${REGISTRY}/${svc}:latest"
done

echo ""
echo "==========================================================="
echo "PRONTO! Use este valor no lugar de REPLACE_ECR_URI nos manifestos:"
echo "  ${REGISTRY}"
echo "Ex: sed -i \"s|REPLACE_ECR_URI|${REGISTRY}|g\" k8s/*.yaml"
echo "==========================================================="
