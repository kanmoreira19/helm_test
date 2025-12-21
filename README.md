# MyApp Helm Chart

Chart Helm completo e pronto para produção com todas as melhores práticas do Kubernetes.

## 📋 Pré-requisitos

- Kubernetes 1.19+
- Helm 3.0+
- (Opcional) Ingress Controller para usar Ingress

## 🚀 Instalação Rápida

### 1. Estrutura de Diretórios

Crie a seguinte estrutura:

```
myapp/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── serviceaccount.yaml
    ├── hpa.yaml
    ├── configmap.yaml
    ├── secret.yaml
    └── NOTES.txt
```

### 2. Instalação Básica

```bash
# Instalar com valores padrão
helm install myapp ./myapp

# Instalar em namespace específico
helm install myapp ./myapp -n production --create-namespace

# Instalar com dry-run para testar
helm install myapp ./myapp --dry-run --debug
```

### 3. Instalação com Valores Customizados

```bash
# Criar arquivo de valores customizados
cat > custom-values.yaml <<EOF
replicaCount: 3

image:
  repository: nginx
  tag: "1.25.3"

ingress:
  enabled: true
  hosts:
    - host: myapp.local
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
EOF

# Instalar com valores customizados
helm install myapp ./myapp -f custom-values.yaml
```

## 🔧 Configuração

### Parâmetros Principais

| Parâmetro | Descrição | Valor Padrão |
|-----------|-----------|--------------|
| `replicaCount` | Número de réplicas | `2` |
| `image.repository` | Repositório da imagem | `nginx` |
| `image.tag` | Tag da imagem | `1.25.3` |
| `service.type` | Tipo do Service | `ClusterIP` |
| `service.port` | Porta do Service | `80` |
| `ingress.enabled` | Habilitar Ingress | `false` |
| `resources.limits.cpu` | Limite de CPU | `500m` |
| `resources.limits.memory` | Limite de memória | `512Mi` |

### Probes Configuráveis

```yaml
livenessProbe:
  enabled: true
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5

startupProbe:
  enabled: false  # Habilite para apps com startup lento
  httpGet:
    path: /health
    port: http
  failureThreshold: 30
```

### Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Ingress com TLS

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
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

## 📦 Instalação no MicroK8s

### 1. Preparar o MicroK8s

```bash
# Instalar MicroK8s
sudo snap install microk8s --classic

# Adicionar seu usuário ao grupo
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
newgrp microk8s

# Habilitar addons necessários
microk8s enable dns storage helm3

# (Opcional) Habilitar ingress
microk8s enable ingress

# Verificar status
microk8s status
```

### 2. Instalar o Chart

```bash
# Usar helm do MicroK8s
microk8s helm3 install myapp ./myapp

# Ou criar alias
alias helm='microk8s helm3'
alias kubectl='microk8s kubectl'

helm install myapp ./myapp
```

### 3. Acessar a Aplicação

```bash
# Via port-forward
kubectl port-forward svc/myapp 8080:80

# Acessar: http://localhost:8080

# Via NodePort (se configurado)
kubectl get svc myapp
```

## 🐳 Instalação no Docker Desktop (Kubernetes)

### 1. Habilitar Kubernetes no Docker Desktop

- Abra Docker Desktop
- Settings → Kubernetes → Enable Kubernetes
- Aguarde o cluster inicializar

### 2. Instalar Ingress Controller (opcional)

```bash
# Instalar nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx

# Aguardar estar pronto
kubectl wait --namespace default \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 3. Instalar o Chart

```bash
helm install myapp ./myapp

# Com Ingress habilitado
helm install myapp ./myapp \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.local \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

### 4. Configurar /etc/hosts (para Ingress)

```bash
# Linux/Mac
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts

# Windows (como Admin no PowerShell)
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 myapp.local"
```

## 🧪 Validação e Testes

### Validar o Chart

```bash
# Lint do chart
helm lint ./myapp

# Dry-run para ver os manifestos gerados
helm install myapp ./myapp --dry-run --debug

# Template para ver os YAMLs finais
helm template myapp ./myapp > output.yaml
```

### Testar a Instalação

```bash
# Ver recursos criados
kubectl get all -l app.kubernetes.io/instance=myapp

# Ver logs
kubectl logs -l app.kubernetes.io/name=myapp -f

# Testar conectividade
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://myapp:80
```

## 🔄 Gerenciamento

### Atualizar o Release

```bash
# Atualizar com novos valores
helm upgrade myapp ./myapp -f new-values.yaml

# Atualizar apenas uma configuração
helm upgrade myapp ./myapp --set replicaCount=5

# Ver histórico
helm history myapp
```

### Rollback

```bash
# Voltar para versão anterior
helm rollback myapp

# Voltar para revisão específica
helm rollback myapp 2
```

### Desinstalar

```bash
# Desinstalar o release
helm uninstall myapp

# Desinstalar mantendo o histórico
helm uninstall myapp --keep-history
```

## 📊 Monitoramento

```bash
# Status do deployment
kubectl rollout status deployment/myapp

# Métricas dos pods
kubectl top pods -l app.kubernetes.io/name=myapp

# Ver HPA (se habilitado)
kubectl get hpa myapp

# Eventos
kubectl get events --sort-by='.lastTimestamp' | grep myapp
```

## 🛠️ Troubleshooting

### Pods não iniciam

```bash
# Descrever o pod
kubectl describe pod -l app.kubernetes.io/name=myapp

# Ver logs
kubectl logs -l app.kubernetes.io/name=myapp --previous

# Ver eventos
kubectl get events --field-selector involvedObject.name=myapp
```

### Probes falhando

```bash
# Verificar probes
kubectl describe pod <pod-name> | grep -A 5 "Liveness\|Readiness"

# Testar endpoint manualmente
kubectl port-forward pod/<pod-name> 8080:8080
curl http://localhost:8080/health
```

### Ingress não funciona

```bash
# Verificar ingress
kubectl describe ingress myapp

# Ver logs do ingress controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

## 📝 Exemplos de Uso

### Exemplo 1: Aplicação com ConfigMap

```yaml
# custom-values.yaml
configMap:
  enabled: true
  data:
    APP_NAME: "MyApp"
    LOG_LEVEL: "info"

env:
  - name: APP_NAME
    valueFrom:
      configMapKeyRef:
        name: myapp
        key: APP_NAME
```

### Exemplo 2: Aplicação com Secrets

```yaml
secret:
  enabled: true
  data:
    api-key: "bXktc2VjcmV0LWtleQ=="  # base64 encoded

env:
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: myapp
        key: api-key
```

### Exemplo 3: Produção com Alta Disponibilidade

```yaml
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

affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - myapp
        topologyKey: kubernetes.io/hostname
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT.

## 📞 Suporte

- Issues: https://github.com/seu-usuario/myapp/issues
- Docs: https://github.com/seu-usuario/myapp/wiki
