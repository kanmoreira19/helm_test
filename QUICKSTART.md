# 🚀 Quick Start - MyApp Helm Chart

Instalação rápida do chart em 5 minutos!

## 📁 Estrutura Final do Projeto

```
myapp/
├── Chart.yaml                  # Metadados do chart
├── values.yaml                 # Valores configuráveis
├── README.md                   # Documentação completa
├── QUICKSTART.md              # Este arquivo
├── install.sh                  # Script de instalação
├── charts/                     # Dependências (vazio por enquanto)
└── templates/
    ├── _helpers.tpl           # Funções auxiliares
    ├── deployment.yaml        # Deployment parametrizado
    ├── service.yaml           # Service
    ├── ingress.yaml           # Ingress condicional
    ├── serviceaccount.yaml    # Service Account
    ├── hpa.yaml               # HPA condicional
    ├── configmap.yaml         # ConfigMap condicional
    ├── secret.yaml            # Secret condicional
    └── NOTES.txt              # Mensagens pós-instalação
```

## ⚡ Instalação em 3 Passos

### Passo 1: Criar a estrutura

```bash
# Criar diretórios
mkdir -p myapp/{templates,charts}
cd myapp

# Copiar todos os arquivos fornecidos para seus respectivos locais
```

### Passo 2: Validar o chart

```bash
# Validar sintaxe
helm lint .

# Ver templates gerados (sem instalar)
helm template myapp . > output.yaml
cat output.yaml
```

### Passo 3: Instalar

```bash
# Instalação padrão
helm install myapp .

# OU usando o script
chmod +x install.sh
./install.sh
```

## 🎯 Instalações Específicas por Plataforma

### MicroK8s

```bash
# Preparar MicroK8s
microk8s enable dns storage helm3

# Método 1: Usando o script
./install.sh --microk8s --name myapp-dev --namespace dev --create-namespace

# Método 2: Manualmente
microk8s helm3 install myapp . -n dev --create-namespace

# Acessar
microk8s kubectl port-forward svc/myapp 8080:80 -n dev
```

### Docker Desktop

```bash
# Garantir que Kubernetes está habilitado
kubectl cluster-info

# Instalar
helm install myapp .

# Acessar
kubectl port-forward svc/myapp 8080:80
```

### Minikube

```bash
# Iniciar Minikube
minikube start

# Instalar
helm install myapp .

# Acessar via NodePort
minikube service myapp
```

### Kind

```bash
# Criar cluster
kind create cluster --name myapp-cluster

# Instalar
helm install myapp .

# Acessar
kubectl port-forward svc/myapp 8080:80
```

## 📝 Exemplos de Instalação

### 1. Desenvolvimento (Simples)

```bash
./install.sh \
  --name myapp-dev \
  --namespace dev \
  --env dev \
  --create-namespace
```

Ou com arquivo de valores:

```yaml
# dev-values.yaml
replicaCount: 1
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

```bash
helm install myapp-dev . -f dev-values.yaml -n dev --create-namespace
```

### 2. Staging (Médio)

```bash
./install.sh \
  --name myapp-staging \
  --namespace staging \
  --env staging \
  --create-namespace
```

### 3. Produção (Alta Disponibilidade)

```bash
./install.sh \
  --name myapp-prod \
  --namespace production \
  --env prod \
  --create-namespace
```

Ou manualmente:

```yaml
# prod-values.yaml
replicaCount: 3

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

```bash
helm install myapp-prod . -f prod-values.yaml -n production --create-namespace
```

### 4. Com ConfigMap e Secret

```yaml
# app-values.yaml
configMap:
  enabled: true
  data:
    APP_NAME: "MyAwesomeApp"
    LOG_LEVEL: "info"
    ENVIRONMENT: "production"

secret:
  enabled: true
  data:
    api-key: "bXktc3VwZXItc2VjcmV0LWtleQ=="  # base64: my-super-secret-key

env:
  - name: APP_NAME
    valueFrom:
      configMapKeyRef:
        name: myapp
        key: APP_NAME
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: myapp
        key: api-key
```

```bash
helm install myapp . -f app-values.yaml
```

## 🧪 Testar Antes de Instalar

```bash
# Dry-run completo (ver todos os manifestos)
helm install myapp . --dry-run --debug

# Usando o script
./install.sh --dry-run

# Ver apenas os templates renderizados
helm template myapp . > test-output.yaml
cat test-output.yaml
```

## ✅ Verificar Instalação

```bash
# Status do release
helm status myapp

# Ver todos os recursos
kubectl get all -l app.kubernetes.io/instance=myapp

# Ver pods
kubectl get pods -l app.kubernetes.io/name=myapp

# Ver logs
kubectl logs -l app.kubernetes.io/name=myapp -f

# Descrever deployment
kubectl describe deployment myapp
```

## 🔄 Atualizar

```bash
# Atualizar valores
helm upgrade myapp . --set replicaCount=5

# Atualizar com novo arquivo de valores
helm upgrade myapp . -f new-values.yaml

# Ver histórico
helm history myapp

# Rollback se necessário
helm rollback myapp
```

## 🗑️ Desinstalar

```bash
# Desinstalar completamente
helm uninstall myapp

# Desinstalar mantendo histórico
helm uninstall myapp --keep-history

# Limpar namespace (se criado)
kubectl delete namespace dev
```

## 🐛 Troubleshooting Rápido

### Pods não iniciam

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

### Probes falhando

```bash
# Verificar endpoints
kubectl exec -it <pod-name> -- curl localhost:8080/health

# Desabilitar probes temporariamente
helm upgrade myapp . --set livenessProbe.enabled=false --set readinessProbe.enabled=false
```

### Recursos insuficientes

```bash
# Ver recursos disponíveis
kubectl top nodes
kubectl top pods

# Reduzir recursos
helm upgrade myapp . \
  --set resources.requests.cpu=50m \
  --set resources.requests.memory=64Mi
```

## 📊 Monitoramento Básico

```bash
# Watch pods
kubectl get pods -w -l app.kubernetes.io/name=myapp

# Métricas
kubectl top pods -l app.kubernetes.io/name=myapp

# HPA (se habilitado)
kubectl get hpa myapp

# Eventos em tempo real
kubectl get events -w
```

## 🎓 Próximos Passos

1. **Customizar a imagem**: Troque `image.repository` para sua aplicação
2. **Configurar Ingress**: Habilite e configure para acesso externo
3. **Adicionar monitoramento**: Integre com Prometheus/Grafana
4. **Configurar CI/CD**: Automatize deploys via GitLab/GitHub Actions
5. **Adicionar testes**: Use `helm test` para validações automáticas

## 📚 Recursos Úteis

- [Helm Docs](https://helm.sh/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)

## 💡 Dicas

1. Sempre use `helm lint` antes de instalar
2. Use `--dry-run` para testar mudanças
3. Versione seus arquivos de valores no Git
4. Mantenha ambientes separados (dev/staging/prod)
5. Use namespaces para isolamento
6. Configure resource limits adequados
7. Habilite probes para health checks
8. Use autoscaling em produção

Pronto! Seu chart está pronto para uso. 🚀
