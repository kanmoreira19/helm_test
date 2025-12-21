#!/bin/bash

# Script de instalação do MyApp Helm Chart
# Suporta: MicroK8s, Docker Desktop, Kind, Minikube

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variáveis padrão
RELEASE_NAME="myapp"
NAMESPACE="default"
CHART_PATH="./myapp"
VALUES_FILE=""
DRY_RUN=false
ENVIRONMENT=""

# Funções auxiliares
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
Uso: $0 [OPÇÕES]

Instalação do MyApp Helm Chart

OPÇÕES:
    -n, --name NAME          Nome do release (padrão: myapp)
    -ns, --namespace NS      Namespace (padrão: default)
    -f, --values FILE        Arquivo de valores customizados
    -e, --env ENV            Ambiente (dev|staging|prod)
    -d, --dry-run           Executar em modo dry-run
    --microk8s              Usar MicroK8s
    --docker-desktop        Usar Docker Desktop
    --create-namespace      Criar namespace se não existir
    -h, --help              Mostrar esta ajuda

EXEMPLOS:
    # Instalação básica
    $0

    # Instalação em produção
    $0 --name myapp-prod --namespace production --env prod --create-namespace

    # Instalação com valores customizados
    $0 -f custom-values.yaml

    # Instalação no MicroK8s
    $0 --microk8s --name myapp-dev --namespace dev

    # Dry-run para testar
    $0 --dry-run --debug

EOF
    exit 0
}

# Detectar ambiente Kubernetes
detect_k8s_environment() {
    if command -v microk8s &> /dev/null; then
        log_info "MicroK8s detectado"
        KUBECTL="microk8s kubectl"
        HELM="microk8s helm3"
        return 0
    elif kubectl config current-context | grep -q "docker-desktop"; then
        log_info "Docker Desktop detectado"
        KUBECTL="kubectl"
        HELM="helm"
        return 0
    elif kubectl config current-context | grep -q "minikube"; then
        log_info "Minikube detectado"
        KUBECTL="kubectl"
        HELM="helm"
        return 0
    elif kubectl config current-context | grep -q "kind"; then
        log_info "Kind detectado"
        KUBECTL="kubectl"
        HELM="helm"
        return 0
    else
        log_info "Kubernetes padrão detectado"
        KUBECTL="kubectl"
        HELM="helm"
        return 0
    fi
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."

    # Verificar kubectl
    if ! command -v $KUBECTL &> /dev/null; then
        log_error "kubectl não encontrado. Por favor, instale o Kubernetes."
        exit 1
    fi

    # Verificar helm
    if ! command -v $HELM &> /dev/null; then
        log_error "Helm não encontrado. Por favor, instale o Helm 3."
        exit 1
    fi

    # Verificar conectividade com cluster
    if ! $KUBECTL cluster-info &> /dev/null; then
        log_error "Não foi possível conectar ao cluster Kubernetes."
        exit 1
    fi

    # Verificar se o chart existe
    if [ ! -d "$CHART_PATH" ]; then
        log_error "Chart não encontrado em: $CHART_PATH"
        exit 1
    fi

    log_info "✓ Todos os pré-requisitos atendidos"
}

# Validar o chart
validate_chart() {
    log_info "Validando o chart..."
    
    if ! $HELM lint "$CHART_PATH" &> /dev/null; then
        log_error "Validação do chart falhou"
        $HELM lint "$CHART_PATH"
        exit 1
    fi
    
    log_info "✓ Chart válido"
}

# Criar namespace se necessário
create_namespace_if_needed() {
    if [ "$CREATE_NAMESPACE" = true ]; then
        if ! $KUBECTL get namespace "$NAMESPACE" &> /dev/null; then
            log_info "Criando namespace: $NAMESPACE"
            $KUBECTL create namespace "$NAMESPACE"
        else
            log_info "Namespace $NAMESPACE já existe"
        fi
    fi
}

# Preparar valores baseado no ambiente
prepare_values() {
    local temp_values="/tmp/myapp-values-${ENVIRONMENT}.yaml"
    
    case "$ENVIRONMENT" in
        dev)
            cat > "$temp_values" <<EOF
replicaCount: 1
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
ingress:
  enabled: false
autoscaling:
  enabled: false
EOF
            ;;
        staging)
            cat > "$temp_values" <<EOF
replicaCount: 2
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
ingress:
  enabled: true
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
EOF
            ;;
        prod)
            cat > "$temp_values" <<EOF
replicaCount: 3
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
ingress:
  enabled: true
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - myapp
          topologyKey: kubernetes.io/hostname
EOF
            ;;
    esac
    
    if [ -f "$temp_values" ]; then
        VALUES_FILE="$temp_values"
        log_info "Usando valores para ambiente: $ENVIRONMENT"
    fi
}

# Instalar o chart
install_chart() {
    log_info "Instalando o chart..."
    
    local install_cmd="$HELM install $RELEASE_NAME $CHART_PATH"
    
    if [ -n "$NAMESPACE" ]; then
        install_cmd="$install_cmd --namespace $NAMESPACE"
    fi
    
    if [ -n "$VALUES_FILE" ]; then
        install_cmd="$install_cmd --values $VALUES_FILE"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        install_cmd="$install_cmd --dry-run --debug"
    fi
    
    log_info "Executando: $install_cmd"
    
    if $install_cmd; then
        log_info "✓ Chart instalado com sucesso!"
        
        if [ "$DRY_RUN" = false ]; then
            show_post_install_info
        fi
    else
        log_error "Falha na instalação do chart"
        exit 1
    fi
}

# Mostrar informações pós-instalação
show_post_install_info() {
    echo ""
    echo "=========================================="
    echo "  INSTALAÇÃO CONCLUÍDA COM SUCESSO! 🎉"
    echo "=========================================="
    echo ""
    echo "Release: $RELEASE_NAME"
    echo "Namespace: $NAMESPACE"
    echo ""
    echo "Comandos úteis:"
    echo ""
    echo "  # Ver status dos pods"
    echo "  $KUBECTL get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"
    echo ""
    echo "  # Ver logs"
    echo "  $KUBECTL logs -n $NAMESPACE -l app.kubernetes.io/name=myapp -f"
    echo ""
    echo "  # Acessar a aplicação (port-forward)"
    echo "  $KUBECTL port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:80"
    echo "  Em seguida acesse: http://localhost:8080"
    echo ""
    echo "  # Ver status do Helm release"
    echo "  $HELM status $RELEASE_NAME -n $NAMESPACE"
    echo ""
    echo "  # Atualizar o release"
    echo "  $HELM upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE"
    echo ""
    echo "  # Desinstalar"
    echo "  $HELM uninstall $RELEASE_NAME -n $NAMESPACE"
    echo ""
}

# Parse dos argumentos
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                RELEASE_NAME="$2"
                shift 2
                ;;
            -ns|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -f|--values)
                VALUES_FILE="$2"
                shift 2
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --microk8s)
                KUBECTL="microk8s kubectl"
                HELM="microk8s helm3"
                shift
                ;;
            --docker-desktop)
                KUBECTL="kubectl"
                HELM="helm"
                shift
                ;;
            --create-namespace)
                CREATE_NAMESPACE=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                ;;
        esac
    done
}

# Main
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   MyApp Helm Chart - Instalação       ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    parse_arguments "$@"
    detect_k8s_environment
    check_prerequisites
    validate_chart
    
    if [ -n "$ENVIRONMENT" ]; then
        prepare_values
    fi
    
    create_namespace_if_needed
    install_chart
}

# Executar
main "$@"
