variable "aws_region" {
  description = "Região onde tudo é criado."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo usado nos nomes dos recursos."
  type        = string
  default     = "togglemaster"
}

variable "gitops_repo_url" {
  description = "Repositório GitOps que o ArgoCD observa. Precisa ser clonável sem credencial (público) ou o sync falha."
  type        = string
  default     = "https://github.com/souza-wallace/togglemaster-k8s.git"
}

variable "gitops_target_revision" {
  description = "Branch ou tag acompanhada pelo ArgoCD."
  type        = string
  default     = "master"
}
