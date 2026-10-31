# Três instâncias PostgreSQL independentes, uma por serviço.
# A senha é gerada pelo RDS e guardada no Secrets Manager (manage_master_user_password).

resource "aws_db_subnet_group" "main" {
  name = "${var.project}-rds"
  subnet_ids = [
    aws_subnet.private_data_a.id,
    aws_subnet.private_data_b.id,
  ]
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds"
  description = "PostgreSQL acessivel apenas a partir do EKS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-rds"
  }
}

# Libera a porta 5432 só para o security group que o EKS criou para o cluster e os nodes.
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# ---------- auth-service ----------

resource "aws_db_instance" "auth" {
  identifier     = "${var.project}-auth"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "auth_db"
  username                    = "togglemaster"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  apply_immediately       = true
}

# ---------- flag-service ----------

resource "aws_db_instance" "flag" {
  identifier     = "${var.project}-flag"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "flags_db"
  username                    = "togglemaster"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  apply_immediately       = true
}

# ---------- targeting-service ----------

resource "aws_db_instance" "targeting" {
  identifier     = "${var.project}-targeting"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "targeting_db"
  username                    = "togglemaster"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  apply_immediately       = true
}
