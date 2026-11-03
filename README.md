# iac-togglemaster

Infraestrutura AWS do ToggleMaster, descrita em Terraform.

Sobe a rede, o cluster EKS e os recursos que os serviços usam: RDS, Redis, SQS, DynamoDB, ECR e os papéis IAM (IRSA). No cluster, instala Argo CD, ingress-nginx, metrics-server, KEDA e External Secrets.

Os manifests dos microsserviços ficam no repositório `togglemaster-k8s`. O Argo CD lê esse repositório e aplica no cluster. O CI publica a imagem no ECR e atualiza a tag lá; este repositório não faz o deploy da aplicação.
