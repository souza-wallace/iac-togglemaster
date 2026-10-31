# Segredos da aplicação no AWS Secrets Manager e a role que o External Secrets usa para lê-los.
#
# Fluxo:
#   Secrets Manager  ->  External Secrets Operator (pod no cluster, com esta role)  ->  Secret do Kubernetes  ->  pod
#
# No repositório GitOps (público) fica só o ExternalSecret, que diz QUAL segredo buscar.
# O valor nunca passa pelo Git.
#
# Senhas dos bancos: o próprio RDS cria um segredo por instância (manage_master_user_password em rds.tf).
# Chaves da aplicação: os dois segredos abaixo nascem vazios. O valor é gravado pela CLI,
# para não ficar no código nem no terraform.tfstate:
#
#   aws secretsmanager put-secret-value --secret-id togglemaster/auth/master-key --secret-string "$(openssl rand -hex 32)"
#   aws secretsmanager put-secret-value --secret-id togglemaster/evaluation/service-api-key --secret-string "tm_key_..."

# MASTER_KEY do auth-service: protege a rota /admin/keys, que cria chaves de API.
resource "aws_secretsmanager_secret" "auth_master_key" {
  name = "${var.project}/auth/master-key"

  # 0 = apaga na hora no destroy. Sem isso a AWS segura o nome por 7 a 30 dias
  # e o próximo apply falha com "already scheduled for deletion".
  recovery_window_in_days = 0
}

# SERVICE_API_KEY do evaluation-service: chave tm_key_... criada pelo auth-service em /admin/keys.
resource "aws_secretsmanager_secret" "evaluation_service_api_key" {
  name                    = "${var.project}/evaluation/service-api-key"
  recovery_window_in_days = 0
}

# ---------- Role do External Secrets Operator (IRSA) ----------
# Mesmo padrão do irsa.tf: QUEM pode usar (o ServiceAccount do ESO) e O QUE pode fazer (ler estes 5 segredos).

resource "aws_iam_role" "external_secrets" {
  name = "${var.project}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
            "${local.oidc_issuer}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_secrets_read" {
  name = "read-app-secrets"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = [
          aws_db_instance.auth.master_user_secret[0].secret_arn,
          aws_db_instance.flag.master_user_secret[0].secret_arn,
          aws_db_instance.targeting.master_user_secret[0].secret_arn,
          aws_secretsmanager_secret.auth_master_key.arn,
          aws_secretsmanager_secret.evaluation_service_api_key.arn,
        ]
      }
    ]
  })
}
