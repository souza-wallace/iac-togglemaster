# VPC 10.0.0.0/16 em duas AZs (us-east-1a e us-east-1b).
#
#   pública       10.0.1.0/24  (a)   10.0.2.0/24  (b)   -> NLB e NAT
#   privada app   10.0.10.0/24 (a)   10.0.11.0/24 (b)   -> nodes e pods do EKS
#   privada dados 10.0.20.0/24 (a)   10.0.21.0/24 (b)   -> RDS e Redis

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-igw"
  }
}

# ---------- Subnets públicas ----------
# A tag kubernetes.io/role/elb diz ao Kubernetes onde criar o load balancer público.

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                     = "${var.project}-public-a"
    "kubernetes.io/role/elb"                 = "1"
    "kubernetes.io/cluster/togglemaster-eks" = "shared"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                     = "${var.project}-public-b"
    "kubernetes.io/role/elb"                 = "1"
    "kubernetes.io/cluster/togglemaster-eks" = "shared"
  }
}

# ---------- Subnets privadas de aplicação (EKS) ----------

resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name                                     = "${var.project}-private-app-a"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/togglemaster-eks" = "shared"
  }
}

resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                                     = "${var.project}-private-app-b"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/togglemaster-eks" = "shared"
  }
}

# ---------- Subnets privadas de dados (RDS e Redis) ----------

resource "aws_subnet" "private_data_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.project}-private-data-a"
  }
}

resource "aws_subnet" "private_data_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.project}-private-data-b"
  }
}

# ---------- NAT: saída para a internet das subnets de aplicação ----------
# Sem ele os nodes não puxam imagem do ECR nem falam com SQS e DynamoDB.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-nat"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.project}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# ---------- Route tables ----------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-public"
  }
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project}-private-app"
  }
}

# Sem rota para a internet: os bancos só conversam dentro da VPC.
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-private-data"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_data_a" {
  subnet_id      = aws_subnet.private_data_a.id
  route_table_id = aws_route_table.private_data.id
}

resource "aws_route_table_association" "private_data_b" {
  subnet_id      = aws_subnet.private_data_b.id
  route_table_id = aws_route_table.private_data.id
}
