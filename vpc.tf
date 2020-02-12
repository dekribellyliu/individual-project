# Create VPC
resource "aws_vpc" "belly-vpc" {
    cidr_block = "100.100.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    tags = {
        Name = var.vpc-name
    }
}

# Create Elastic IP
resource "aws_eip" "belly-eip" {
  vpc = true
  
  tags = {
    Name = var.eip-tag
  }
}

# Create NAT GW
resource "aws_nat_gateway" "belly-nat" {
  allocation_id = aws_eip.belly-eip.id
  subnet_id = aws_subnet.belly-subnet-public-1.id
  
  depends_on = [aws_subnet.belly-subnet-public-1]

  tags = {
    Name = var.nat-name
  }
}

# Create public-subnet-1
resource "aws_subnet" "belly-subnet-public-1" {
    vpc_id = aws_vpc.belly-vpc.id
    cidr_block = var.subnet-cidr["public-1"]
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = var.az["a"]
    tags = {
        Name = var.subnet-name["public-1"]
    }
    depends_on = [aws_vpc.belly-vpc]
}

# Create public-subnet-2
resource "aws_subnet" "belly-subnet-public-2" {
    vpc_id = aws_vpc.belly-vpc.id
    cidr_block = var.subnet-cidr["public-2"]
    map_public_ip_on_launch = "true"
    availability_zone = var.az["b"]
    tags = {
        Name = var.subnet-name["public-2"]
    }
    depends_on = [aws_vpc.belly-vpc]
}
 
# Create private-subnet-1
resource "aws_subnet" "belly-subnet-private-1" {
    vpc_id = aws_vpc.belly-vpc.id
    cidr_block = var.subnet-cidr["private-1"]
    map_public_ip_on_launch = "false" //it makes this a private subnet
    availability_zone = var.az["a"]
    tags = {
        Name = var.subnet-name["private-1"]
    }
    depends_on = [aws_vpc.belly-vpc]
}

# Create private-subnet-2
resource "aws_subnet" "belly-subnet-private-2" {
    vpc_id = aws_vpc.belly-vpc.id
    cidr_block = var.subnet-cidr["private-2"]
    map_public_ip_on_launch = "false"
    availability_zone = var.az["b"]
    tags = {
        Name = var.subnet-name["private-2"]
    }
    depends_on = [aws_vpc.belly-vpc]
}

# create I-GW and associate with VPC using vpc.id
resource "aws_internet_gateway" "belly-gw" {
  vpc_id    = aws_vpc.belly-vpc.id
  tags  = {
    Name  = var.gw-name
  }
  depends_on = [aws_vpc.belly-vpc]
}

# Create public route table
resource "aws_route_table" "belly-route-table" {
  vpc_id    = aws_vpc.belly-vpc.id

  route {
    cidr_block  = "0.0.0.0/0" # The route destination
    gateway_id  = aws_internet_gateway.belly-gw.id # Reach the route destination using I-GW
  }
  tags  = {
    Name  = var.route-table-name
  }
  depends_on = [aws_internet_gateway.belly-gw]
}

# Create private route table
resource "aws_route_table" "belly-private-route-table" {
  vpc_id = aws_vpc.belly-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.belly-nat.id
  }

  tags = {
    Name = var.route-table-private
  }
}

# Associate subnet's to the route table
resource "aws_route_table_association" "subnet-public1-association" {
  subnet_id = aws_subnet.belly-subnet-public-1.id
  route_table_id = aws_route_table.belly-route-table.id
  depends_on = [aws_route_table.belly-route-table]
}

resource "aws_route_table_association" "subnet-public2-association" {
  subnet_id = aws_subnet.belly-subnet-public-2.id
  route_table_id = aws_route_table.belly-route-table.id
  depends_on = [aws_route_table.belly-route-table]
}

resource "aws_route_table_association" "subnet-private1-association" {
  subnet_id = aws_subnet.belly-subnet-private-1.id
  route_table_id = aws_route_table.belly-private-route-table.id
  depends_on = [aws_route_table.belly-private-route-table]
}

resource "aws_route_table_association" "subnet-private2-association" {
  subnet_id = aws_subnet.belly-subnet-private-2.id
  route_table_id = aws_route_table.belly-private-route-table.id
  depends_on = [aws_route_table.belly-private-route-table]
}