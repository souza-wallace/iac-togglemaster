# Valores que vão para os manifests do Kubernetes. Veja com: terraform output

output "eks_cluster_name" {
  description = "Use em: aws eks update-kubeconfig --name <valor>"
  value       = aws_eks_cluster.main.name
}

output "rds_auth_host" {
  value = aws_db_instance.auth.address
}

output "rds_flag_host" {
  value = aws_db_instance.flag.address
}

output "rds_targeting_host" {
  value = aws_db_instance.targeting.address
}

output "rds_auth_secret_arn" {
  description = "Segredo com usuário e senha no Secrets Manager"
  value       = aws_db_instance.auth.master_user_secret[0].secret_arn
}

output "rds_flag_secret_arn" {
  value = aws_db_instance.flag.master_user_secret[0].secret_arn
}

output "rds_targeting_secret_arn" {
  value = aws_db_instance.targeting.master_user_secret[0].secret_arn
}

output "redis_url" {
  description = "REDIS_URL do evaluation-service"
  value       = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
}

output "sqs_queue_url" {
  description = "AWS_SQS_URL do evaluation e do analytics"
  value       = aws_sqs_queue.events.url
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "ecr_auth_url" {
  value = aws_ecr_repository.auth.repository_url
}

output "ecr_flag_url" {
  value = aws_ecr_repository.flag.repository_url
}

output "ecr_targeting_url" {
  value = aws_ecr_repository.targeting.repository_url
}

output "ecr_evaluation_url" {
  value = aws_ecr_repository.evaluation.repository_url
}

output "ecr_analytics_url" {
  value = aws_ecr_repository.analytics.repository_url
}

output "irsa_evaluation_role_arn" {
  description = "Anotação eks.amazonaws.com/role-arn do ServiceAccount evaluation-service"
  value       = aws_iam_role.evaluation.arn
}

output "irsa_analytics_role_arn" {
  description = "Anotação eks.amazonaws.com/role-arn dos ServiceAccounts analytics-service e keda-operator"
  value       = aws_iam_role.analytics.arn
}

output "secret_auth_master_key_name" {
  description = "Segredo do MASTER_KEY. Grave o valor com aws secretsmanager put-secret-value."
  value       = aws_secretsmanager_secret.auth_master_key.name
}

output "secret_evaluation_service_api_key_name" {
  description = "Segredo do SERVICE_API_KEY. Grave a chave tm_key_... criada no auth-service."
  value       = aws_secretsmanager_secret.evaluation_service_api_key.name
}

output "github_actions_user" {
  description = "Usuário do CI. Gere a chave com: aws iam create-access-key --user-name <valor>"
  value       = aws_iam_user.github_actions.name
}

output "argocd_namespace" {
  description = "Namespace do ArgoCD. A interface não tem load balancer: use o port-forward abaixo."
  value       = helm_release.argocd.namespace
}

output "argocd_port_forward" {
  description = "Abre a UI em http://localhost:8080 (usuário admin)."
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:80"
}

output "argocd_initial_password" {
  description = "Senha inicial do usuário admin. O secret existe só depois do apply."
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
