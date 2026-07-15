#!/usr/bin/env bash
# =============================================================================
# Configura o cluster EKS: Metrics Server (para HPA) + Nginx Ingress Controller.
# Requer que o kubectl já esteja apontando para o cluster:
#   aws eks update-kubeconfig --name <NOME_DO_CLUSTER> --region us-east-1
# Rode:  bash aws/04-cluster-setup.sh
# =============================================================================
set -euo pipefail

echo ">> Instalando Metrics Server (necessário para o HPA)..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo ">> Instalando Nginx Ingress Controller via Helm..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

echo ">> Aguardando o Metrics Server ficar disponível..."
kubectl rollout status deployment/metrics-server -n kube-system --timeout=180s || true

echo ""
echo ">> Aguardando o LoadBalancer do Nginx receber um endereço público (pode levar 2-3 min)..."
echo "   Acompanhe com: kubectl get svc -n ingress-nginx ingress-nginx-controller -w"
kubectl get svc -n ingress-nginx ingress-nginx-controller
