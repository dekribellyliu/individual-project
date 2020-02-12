# ALB SG
resource "aws_security_group" "belly-alb-sg" {
  vpc_id = aws_vpc.belly-vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-name
  }
}

# PRIVATE SG
resource "aws_security_group" "belly-private-instance-sg" {
  vpc_id = aws_vpc.belly-vpc.id  

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = var.private-sg-name
  }
}

resource "aws_security_group_rule" "allow-from-belly-alb-sg" {
  type  = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  security_group_id = aws_security_group.belly-private-instance-sg.id  
  source_security_group_id = aws_security_group.belly-alb-sg.id  
}

resource "aws_security_group_rule" "allow-from-bastion-sg" {
  type  = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.belly-private-instance-sg.id  
  source_security_group_id = aws_security_group.belly-bastion-sg.id  
}

# BASTION SG
resource "aws_security_group" "belly-bastion-sg" {
  vpc_id = aws_vpc.belly-vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-bastion
  }
}