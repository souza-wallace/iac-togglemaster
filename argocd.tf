# ArgoCD no EKS, instalado pelo provider Helm.
#
# O CI não dá kubectl apply. Ele só commita a tag nova no deployment.yaml
# do repositório GitOps. O ArgoCD compara esse Git com o cluster e aplica
# a diferença sozinho (sync automático).

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.11.6"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 900

  # dex e notifications desligados: não entram no fluxo deste trabalho e ocupam CPU dos nodes.
  # timeout.reconciliation 30s: o padrão é 3 minutos; 30s mostra a tag nova mais rápido no vídeo.
  # server.insecure: HTTP na porta 80, para o port-forward não precisar de certificado.
  values = [<<-YAML
    dex:
      enabled: false
    notifications:
      enabled: false
    configs:
      cm:
        timeout.reconciliation: 30s
      params:
        server.insecure: true
    YAML
  ]

  depends_on = [aws_eks_node_group.main]
}

# Uma Application por microsserviço. Cada uma observa a pasta de mesmo nome
# no repositório GitOps e aplica no namespace de mesmo nome.

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.7"
  namespace  = helm_release.argocd.namespace
  timeout    = 300

  values = [<<-YAML
    applications:
      auth-service:
        namespace: argocd
        project: default
        finalizers:
          - resources-finalizer.argocd.argoproj.io
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_target_revision}
          path: auth-service
        destination:
          server: https://kubernetes.default.svc
          namespace: auth-service
        syncPolicy:
          automated:
            enabled: true
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true

      flag-service:
        namespace: argocd
        project: default
        finalizers:
          - resources-finalizer.argocd.argoproj.io
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_target_revision}
          path: flag-service
        destination:
          server: https://kubernetes.default.svc
          namespace: flag-service
        syncPolicy:
          automated:
            enabled: true
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true

      targeting-service:
        namespace: argocd
        project: default
        finalizers:
          - resources-finalizer.argocd.argoproj.io
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_target_revision}
          path: targeting-service
        destination:
          server: https://kubernetes.default.svc
          namespace: targeting-service
        syncPolicy:
          automated:
            enabled: true
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true

      evaluation-service:
        namespace: argocd
        project: default
        finalizers:
          - resources-finalizer.argocd.argoproj.io
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_target_revision}
          path: evaluation-service
        destination:
          server: https://kubernetes.default.svc
          namespace: evaluation-service
        syncPolicy:
          automated:
            enabled: true
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true

      analytics-service:
        namespace: argocd
        project: default
        finalizers:
          - resources-finalizer.argocd.argoproj.io
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_target_revision}
          path: analytics-service
        destination:
          server: https://kubernetes.default.svc
          namespace: analytics-service
        syncPolicy:
          automated:
            enabled: true
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true
    YAML
  ]

  # As Applications só sobem depois do ingress-nginx (Ingress), do metrics-server (HPA),
  # do KEDA (ScaledObject) e do External Secrets (SecretStore e ExternalSecret),
  # para o primeiro sync já encontrar esses recursos no cluster.
  depends_on = [
    helm_release.argocd,
    helm_release.ingress_nginx,
    helm_release.metrics_server,
    helm_release.keda,
    helm_release.external_secrets,
  ]
}
