# ToggleMaster — Tech Challenge Fase 2 (FIAP POSTECH)

Ecossistema de **feature flags** migrado de monólito para **5 microsserviços** conteinerizados,
orquestrados em **Kubernetes (AWS EKS)**, com autoscaling, Ingress e serviços gerenciados da AWS.

---

## 📋 Relatório de Entrega

### Participante
| | |
|---|---|
| **Nome** | Kaue Matheus Santana Alexandre |
| **RM** | 372355 |
| **Discord** | ksantanac_ |

> Projeto desenvolvido individualmente.

### Links
- **Repositório:** https://github.com/ksantanac/tech-challenge-fase-2
- **Vídeo de demonstração:** https://youtu.be/qQFo31-kttc

---

## 🏗️ Arquitetura da Solução

O ToggleMaster foi quebrado em **5 microsserviços** independentes, orquestrados no **AWS EKS**:

| Microsserviço | Linguagem | Responsabilidade | Data store |
|---|---|---|---|
| `auth-service` | Go | Chaves de API e autenticação | RDS PostgreSQL |
| `flag-service` | Python/Flask | CRUD das feature flags | RDS PostgreSQL |
| `targeting-service` | Python/Flask | Regras de segmentação | RDS PostgreSQL |
| `evaluation-service` | Go | Decisão final (hot path) | ElastiCache Redis + produz no SQS |
| `analytics-service` | Python/Flask | Consome eventos e persiste analytics | SQS (consumidor) + DynamoDB |

**Fluxo síncrono:** requisição → **Load Balancer** → **Nginx Ingress** (roteamento por path:
`/auth`, `/flags`, `/rules`, `/evaluate`) → **Services ClusterIP** → **Pods**.

**Fluxo assíncrono:** o `evaluation-service` publica um evento no **SQS** a cada avaliação;
o `analytics-service` consome a fila e grava no **DynamoDB** — desacoplado e escalável.

> 📊 Diagrama visual da arquitetura: [`docs/arquitetura.html`](docs/arquitetura.html)

## ☁️ Infraestrutura provisionada (AWS)
- 1x cluster **EKS** (`togglemaster-eks`) com Managed Node Group usando a **LabRole**
- 5x repositórios **ECR** (um por microsserviço)
- 3x **RDS PostgreSQL** (auth, flags, targeting)
- 1x **ElastiCache Redis** (cache do evaluation-service)
- 1x tabela **DynamoDB** (`ToggleMasterAnalytics`, PK `event_id`)
- 1x fila **SQS** (`togglemaster-events`, Standard)
- **Metrics Server** + **Nginx Ingress Controller**

## 🗄️ Diferença de propósito entre os 3 data stores
- **RDS (PostgreSQL):** dados **relacionais e transacionais** com consistência forte — chaves de API,
  definições das flags e regras de segmentação. Uma instância por serviço (isolamento de dados).
- **ElastiCache (Redis):** **cache em memória** de baixíssima latência no *hot path* do
  evaluation-service (TTL de 30s). Evita consultar os outros serviços a cada avaliação.
- **DynamoDB (NoSQL):** **gravação em alta escala** de eventos de analytics — append-only,
  schema flexível, ideal para grande volume de escrita.

## 📈 Escalabilidade
- **HPA por CPU** para `evaluation-service` (alvo 70%, 2→10 réplicas) e `analytics-service`
  (alvo 70%, 1→8 réplicas).
- **Justificativa (Opção A / AWS Academy):** a LabRole não permite criar novas IAM Roles (IRSA),
  então o **KEDA não é viável**. Com HPA por CPU: quando a fila SQS enche, o analytics processa mais
  mensagens, a CPU sobe e o HPA adiciona réplicas. Em uma conta pessoal, a evolução natural seria o
  **KEDA**, escalando diretamente pelo tamanho da fila (`queueDepth`), inclusive de 0 a N.

## ✅ Boas práticas aplicadas
- **Dockerfiles multi-stage** (imagens finais enxutas: Go em Alpine, Python em slim)
- **Requests/Limits** de CPU e memória em todos os Deployments
- **Readiness/Liveness probes** em `/health`
- **Secrets** (base64) para credenciais e **ConfigMaps** para configuração não sensível
- Separação lógica por **Namespace** (`togglemaster`)
- Segredos reais **fora do versionamento** (`.gitignore`)

## 🧗 Desafios encontrados
1. **Limitações da LabRole (AWS Academy):** sem permissão para criar IAM Roles → uso de HPA por CPU
   em vez de KEDA; nós com LabRole para os pods herdarem permissões de SQS/DynamoDB.
2. **Modo de autenticação do EKS:** a versão nova do EKS provisiona o cluster no modo
   `authenticationMode: API`, que **ignora o `aws-auth`** e é incompatível com o fluxo da LabRole —
   os nós falhavam ao entrar no cluster ("Instances failed to join"). Solução: recriar o cluster no
   modo `API_AND_CONFIG_MAP`, permitindo autorizar a LabRole como nó via `aws-auth`.
3. **ElastiCache com TLS:** o Redis foi criado com *encryption in-transit*, exigindo conexão
   `rediss://` (TLS) em vez de `redis://`.
4. **Credenciais nos pods (IMDS):** por padrão os nós usam *hop limit* = 1, bloqueando os pods de
   acessarem o serviço de metadados. Ajustado para 2, permitindo que os pods herdem a LabRole para
   acessar SQS e DynamoDB.
5. **Correções no código-fonte:** ajustes de imports em Go e pin do `Werkzeug==2.2.3` nos serviços
   Flask para compatibilidade com Flask 2.2.2.

---

## 📁 Estrutura do repositório

```
.
├── auth-service/ … analytics-service/   # código + Dockerfile de cada microsserviço
├── docker-compose.yml                   # ambiente local completo (9 contêineres)
├── k8s/                                 # manifestos Kubernetes (namespace, deploy, svc, configmap, ingress, hpa)
├── aws/                                 # scripts de provisionamento e demonstração
└── docs/arquitetura.html                # diagrama da arquitetura
```

## 🚀 Rodar localmente

```bash
docker compose up -d      # sobe 5 microsserviços + 2 Postgres + Redis + DynamoDB Local
docker compose ps         # 9 contêineres

# teste rápido
curl http://localhost:8002/health
curl -X POST http://localhost:8002/flags \
  -H "Authorization: Bearer dev-service-key-local-12345" \
  -H "Content-Type: application/json" \
  -d '{"name":"new-checkout","description":"demo","is_enabled":true}'
curl "http://localhost:8004/evaluate?user_id=u1&flag_name=new-checkout"

docker compose down
```

## ☁️ Deploy na AWS (resumo)

```bash
bash aws/01-ecr-push.sh        # cria os 5 repositórios ECR e publica as imagens
bash aws/02-dynamodb-sqs.sh    # cria a tabela DynamoDB e a fila SQS
bash aws/03-migrations.sh      # aplica os schemas nos 3 RDS
bash aws/04-cluster-setup.sh   # instala Metrics Server + Nginx Ingress
kubectl apply -f k8s/          # implanta a aplicação
```

> ⚠️ O `k8s/02-secret.yaml` **não é versionado** (contém credenciais). Gere o seu com
> `bash k8s/generate-secret.sh > k8s/02-secret.yaml` após preencher os endpoints dos RDS.

## 🔌 Portas dos serviços
auth `8001` · flag `8002` · targeting `8003` · evaluation `8004` · analytics `8005`
