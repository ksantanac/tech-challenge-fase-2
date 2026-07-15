#!/usr/bin/env bash
# =============================================================================
# Cria a tabela DynamoDB (analytics-service) e a fila SQS (evaluation->analytics).
# Rode:  bash aws/02-dynamodb-sqs.sh
# =============================================================================
set -euo pipefail

REGION="us-east-1"
TABLE_NAME="ToggleMasterAnalytics"
QUEUE_NAME="togglemaster-events"

echo ">> Criando tabela DynamoDB '${TABLE_NAME}' (PK: event_id)..."
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=event_id,AttributeType=S \
  --key-schema AttributeName=event_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" >/dev/null 2>&1 || echo "   (tabela já existe, seguindo)"

echo ">> Criando fila SQS '${QUEUE_NAME}'..."
QUEUE_URL=$(aws sqs create-queue --queue-name "$QUEUE_NAME" --region "$REGION" \
  --query QueueUrl --output text)

echo ""
echo "==========================================================="
echo "DynamoDB: ${TABLE_NAME}"
echo "SQS URL : ${QUEUE_URL}"
echo ""
echo "Coloque a SQS URL no k8s/01-configmap.yaml em AWS_SQS_URL"
echo "==========================================================="
