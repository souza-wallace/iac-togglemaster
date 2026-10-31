# Complementos do cluster que os manifests do togglemaster-k8s precisam.
# Cada values abaixo é o mesmo YAML que você passaria em helm install -f values.yaml.

# ---------- ingress-nginx ----------
# Cria um Service LoadBalancer, e a AWS cria o NLB público nas subnets públicas.
# As Ingress de cada serviço (/auth, /flags, /rules, ...) usam ingressClassName: nginx.

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.15.1"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 600

  values = [<<-YAML
    controller:
      replicaCount: 1
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    YAML
  ]

  depends_on = [aws_eks_node_group.main]
}

# ---------- metrics-server ----------
# Fornece CPU e memória dos pods para o HPA do evaluation-service.

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"

  values = [<<-YAML
    args:
      - --kubelet-insecure-tls
    YAML
  ]

  depends_on = [aws_eks_node_group.main]
}

# ---------- KEDA ----------
# Instala o CRD ScaledObject e escala o analytics-service pelo tamanho da fila SQS.
# O ServiceAccount keda-operator recebe a role do analytics (ver irsa.tf),
# que é a mesma anotação do arquivo k8s/keda-operator-irsa.yaml.

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = "2.21.0"
  namespace        = "keda"
  create_namespace = true

  values = [<<-YAML
    serviceAccount:
      operator:
        name: keda-operator
        annotations:
          eks.amazonaws.com/role-arn: "${aws_iam_role.analytics.arn}"
    YAML
  ]

  depends_on = [aws_eks_node_group.main]
}

# ---------- External Secrets Operator ----------
# Lê os segredos do Secrets Manager e cria os Secrets do Kubernetes que os pods usam.
# O ServiceAccount external-secrets recebe a role de secrets.tf.
# Cada serviço tem um SecretStore e um ExternalSecret no repositório GitOps.

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "2.14.0"
  namespace        = "external-secrets"
  create_namespace = true

  values = [<<-YAML
    serviceAccount:
      name: external-secrets
      annotations:
        eks.amazonaws.com/role-arn: "${aws_iam_role.external_secrets.arn}"
    YAML
  ]

  depends_on = [aws_eks_node_group.main]
}
