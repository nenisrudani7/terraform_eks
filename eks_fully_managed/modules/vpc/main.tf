# create vpc
resource "aws_vpc" "precta" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "${var.project_name}-vpc"
    mode = "precta"
  }
}

# create internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.precta.id

  tags = {
    mode = "precta"
   
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}
//---------------------------------------------------------------------------------------------
# create public subnet az1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.precta.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

tags = {
  mode = "precta"
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/elb" = "1" #why we use this tag? it is for aws to identify this subnet for load balancer and “This subnet is allowed for Public LoadBalancers”
  "karpenter.sh/discovery" = var.cluster_name
}

}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.precta.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

tags = {
  mode = "precta"
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/elb" = "1"
  "karpenter.sh/discovery" = var.cluster_name
}

}

//---------------------------------------------------------------------------------------------
# create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.precta.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    mode = "precta"
  }
}

# associate public subnet az1 to "public route table"
resource "aws_route_table_association" "public_subnet_az1_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_az2_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route_table.id
}



//---------------------------------------------------------------------------------------------
resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.precta.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = false

tags = {
  mode = "precta"
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/internal-elb" = "1"
  "karpenter.sh/discovery" = var.cluster_name
}

}
resource "aws_subnet" "private_subnet_az2" {
  vpc_id                  = aws_vpc.precta.id
  cidr_block              = var.private_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = false

tags = {
  mode = "precta-1"
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/internal-elb" = "1"
  "karpenter.sh/discovery" = var.cluster_name
}

}



resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-eip"
  }
}  

//---------------------------------------------------------------------------------------------
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_az1.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    mode = "precta"
  }
}

//---------------------------------------------------------------------------------------------
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.precta.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    mode = "precta"
  }
}


resource "aws_route_table_association" "private_nat_az1" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_nat_az2" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_route_table.id
}


#security group for KARPENTER
resource "aws_security_group" "karpenter_nodes" {
  name   = "${var.cluster_name}-karpenter-sg"
  vpc_id = aws_vpc.precta.id

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

# security group for external load balancer
resource "aws_security_group" "load_balancer" {
  name   = "${var.cluster_name}-lb-sg"
  vpc_id = aws_vpc.precta.id

  tags = {
    mode = "precta"
  }
}

resource "aws_security_group_rule" "lb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
  description       = "Allow HTTP inbound"
}

resource "aws_security_group_rule" "lb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
  description       = "Allow HTTPS inbound"
}

resource "aws_security_group_rule" "lb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
  description       = "Allow all outbound"
}

resource "aws_security_group_rule" "karpenter_node_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.karpenter_nodes.id
  description       = "Allow HTTP inbound"
}

resource "aws_security_group_rule" "karpenter_node_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.karpenter_nodes.id
  description       = "Allow HTTPS inbound"
}

# Wherever your SG is defined, add this below it
resource "aws_security_group_rule" "karpenter_node_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.karpenter_nodes.id  # ← reference directly
  description       = "Allow all outbound for Karpenter nodes"
}