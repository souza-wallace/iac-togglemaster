# Redis do evaluation-service (REDIS_URL).

resource "aws_elasticache_subnet_group" "main" {
  name = "${var.project}-redis"
  subnet_ids = [
    aws_subnet.private_data_a.id,
    aws_subnet.private_data_b.id,
  ]
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-redis"
  description = "Redis acessivel apenas a partir do EKS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-redis"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project}-redis"
  description          = "Cache do evaluation-service"

  engine             = "redis"
  engine_version     = "7.1"
  node_type          = "cache.t3.micro"
  num_cache_clusters = 1
  port               = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  apply_immediately          = true
}
