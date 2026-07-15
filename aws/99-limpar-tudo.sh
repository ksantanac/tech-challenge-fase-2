#!/usr/bin/env bash
# =============================================================================
# LIMPEZA - rode DEPOIS de gravar o vídeo para parar de gastar crédito da AWS.
# ATENÇÃO: apaga recursos! Use só quando terminar tudo.
# =============================================================================
set -uo pipefail

REGION="us-east-1"

echo ">> Removendo aplicações e Nginx do cluster..."
kubectl delete -f k8s/ --ignore-not-found=true
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true

echo ">> Apagando fila SQS e tabela DynamoDB..."
QURL=$(aws sqs get-queue-url --queue-name togglemaster-events --region "$REGION" --query QueueUrl --output text 2>/dev/null || echo "")
[ -n "$QURL" ] && aws sqs delete-queue --queue-url "$QURL" --region "$REGION"
aws dynamodb delete-table --table-name ToggleMasterAnalytics --region "$REGION" 2>/dev/null || true

echo ""
echo ">> ATENÇÃO - apague MANUALMENTE pelo Console (para garantir):"
echo "   - Cluster EKS e o Node Group"
echo "   - As 3 instâncias RDS"
echo "   - O cluster ElastiCache Redis"
echo "   - O Load Balancer (ELB/NLB) criado pelo Nginx (se ainda existir)"
echo "   - Os 5 repositórios ECR (opcional)"
echo ""
echo ">> No AWS Academy, encerrar a sessão do lab (End Lab) também derruba a maioria dos recursos."
