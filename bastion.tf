###########################################################
# AWS BASTION HOST
###########################################################
resource "aws_instance" "bastion_instance" {
  ami                    = "ami-05c64f7b4062b0a21"
  subnet_id              =  aws_subnet.belly-subnet-public-2.id #CHANGE THIS
  instance_type          = "t2.micro"

  vpc_security_group_ids = [aws_security_group.belly-bastion-sg.id] #CHANGE THIS
  key_name               = "internship-aws-ssh-keypair" #CHANGE THIS
  ebs_optimized          = "false"
  root_block_device {
    volume_type           = "gp2"    # gp2 = general purpose SSD
    volume_size           = "10"
    delete_on_termination = "true"
  }

  depends_on = [aws_iam_role.ecs-instance-role, aws_route_table_association.subnet-public1-association,
                aws_route_table_association.subnet-public2-association, aws_route_table_association.subnet-private1-association,
                aws_route_table_association.subnet-private2-association]

  tags = {
    Name                   = var.bastion-name
  }
}