# Usuário que o GitHub Actions usa para publicar imagens no ECR.
#
# Nos workflows ele entra pelos secrets AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY
# (aws-actions/configure-aws-credentials). Só pode fazer push nos 5 repositórios
# abaixo: não acessa EKS, RDS, S3 nem nada mais da conta.
#
# A chave de acesso não é criada aqui: o aws_iam_access_key gravaria a secret em
# texto puro no terraform.tfstate. Crie com:
#   aws iam create-access-key --user-name togglemaster-github-actions

resource "aws_iam_user" "github_actions" {
  name = "${var.project}-github-actions"
}

resource "aws_iam_user_policy" "github_actions_ecr_push" {
  name = "ecr-push"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Login no ECR (aws-actions/amazon-ecr-login). A AWS não permite limitar esta ação a um repositório.
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # docker push: confere as camadas que já existem, envia as novas e grava a tag.
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [
          aws_ecr_repository.auth.arn,
          aws_ecr_repository.flag.arn,
          aws_ecr_repository.targeting.arn,
          aws_ecr_repository.evaluation.arn,
          aws_ecr_repository.analytics.arn,
        ]
      }
    ]
  })
}
