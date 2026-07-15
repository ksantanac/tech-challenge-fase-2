#!/usr/bin/env bash
# =============================================================================
# Scripts de DEMONSTRAÇÃO para o vídeo (gerar carga e ver o HPA escalar).
# Uso:
#   bash aws/05-demo-carga.sh evaluate   # gera carga de CPU no evaluation-service
#   bash aws/05-demo-carga.sh sqs        # envia várias mensagens para a fila SQS
# =============================================================================
set -euo pipefail

REGION="us-east-1"
# Endereço público do Nginx Ingress:
#   kubectl get svc -n ingress-nginx ingress-nginx-controller
INGRESS_URL="http://SEU-LOAD-BALANCER.us-east-1.elb.amazonaws.com"
# URL da fila SQS:
#   aws sqs get-queue-url --queue-name togglemaster-events --region us-east-1
QUEUE_URL="https://sqs.us-east-1.amazonaws.com/SUA_CONTA_AWS/togglemaster-events"

case "${1:-}" in
  evaluate)
    echo ">> Gerando carga no evaluation-service por 3 minutos..."
    echo ">> Em outro terminal, rode:  kubectl get hpa -n togglemaster -w"
    # Loop de carga (não precisa instalar 'hey'/'ab'): 20 processos paralelos
    for i in $(seq 1 20); do
      ( end=$((SECONDS+180)); while [ $SECONDS -lt $end ]; do
          curl -s "${INGRESS_URL}/evaluate?user_id=user${i}_${RANDOM}&flag_name=new-checkout" >/dev/null
        done ) &
    done
    wait
    echo ">> Carga finalizada."
    ;;
  sqs)
    echo ">> Inundando a fila SQS com 6 remetentes paralelos por ~2 minutos..."
    echo ">> Em outro terminal, rode:  kubectl get hpa -n togglemaster -w"
    for w in $(seq 1 6); do
      ( end=$((SECONDS+120)); c=0; while [ $SECONDS -lt $end ]; do c=$((c+1))
          aws sqs send-message --region "$REGION" --queue-url "$QUEUE_URL" \
            --message-body "{\"user_id\":\"w${w}n${c}\",\"flag_name\":\"new-checkout\",\"result\":true,\"timestamp\":\"2026-01-01T00:00:00Z\"}" >/dev/null
        done ) &
    done
    wait
    echo ">> Envio finalizado. Os dados estão no DynamoDB:"
    echo "   aws dynamodb scan --table-name ToggleMasterAnalytics --region $REGION --max-items 5"
    ;;
  *)
    echo "Uso: bash aws/05-demo-carga.sh [evaluate|sqs]"; exit 1 ;;
esac
