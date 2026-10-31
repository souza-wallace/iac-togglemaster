# IRSA: permissão AWS para um pod, via o ServiceAccount dele.
#
# Este arquivo cria a role que aparece na anotação do ServiceAccount:
#
#   apiVersion: v1
#   kind: ServiceAccount
#   metadata:
#     name: analytics-service          <- tem que bater com o "sub" do trust abaixo
#     namespace: analytics-service     <- idem
#     annotations:
#       eks.amazonaws.com/role-arn: <output irsa_analytics_role_arn>
#
# assume_role_policy = QUEM pode usar a role (só aquele ServiceAccount daquele cluster).
# aws_iam_role_policy = O QUE a role pode fazer (ler a fila, gravar na tabela...).

locals {
  # Issuer do cluster sem o "https://". Ex.: oidc.eks.us-east-1.amazonaws.com/id/ABC123
  oidc_issuer = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# ---------- evaluation-service: só envia mensagens para a fila ----------

resource "aws_iam_role" "evaluation" {
  name = "${var.project}-evaluation-role"

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
            "${local.oidc_issuer}:sub" = "system:serviceaccount:evaluation-service:evaluation-service"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "evaluation_sqs" {
  name = "send-to-events-queue"
  role = aws_iam_role.evaluation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.events.arn
      }
    ]
  })
}

# ---------- analytics-service: lê a fila e grava no DynamoDB ----------
# O KEDA (namespace keda) usa a mesma role para ler o tamanho da fila e escalar o analytics.

resource "aws_iam_role" "analytics" {
  name = "${var.project}-analytics-role"

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
            "${local.oidc_issuer}:sub" = [
              "system:serviceaccount:analytics-service:analytics-service",
              "system:serviceaccount:keda:keda-operator",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "analytics_sqs_dynamodb" {
  name = "consume-queue-write-table"
  role = aws_iam_role.analytics.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable",
        ]
        Resource = aws_dynamodb_table.analytics.arn
      }
    ]
  })
}
