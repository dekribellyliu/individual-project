##########################################################
# AWS ECS-CLUSTER
#########################################################

resource "aws_ecs_cluster" "cluster" {
  name = "belly-cluster"
  tags = {
   name = var.cluster-name
   }
  }

###########################################################
# AWS ECS-EC2-INSTANCE
###########################################################
resource "aws_instance" "ec2_instance" {
  ami                    = "ami-0a6dd2dfe55885625"
  subnet_id              =  aws_subnet.belly-subnet-private-1.id #CHANGE THIS
  instance_type          = "c5.large"
  iam_instance_profile   = aws_iam_instance_profile.ecs-instance-profile.name #CHANGE THIS
  vpc_security_group_ids = [aws_security_group.belly-private-instance-sg.id] #CHANGE THIS
  key_name               = "internship-aws-ssh-keypair" #CHANGE THIS
  ebs_optimized          = "false"
  source_dest_check      = "false"
  user_data              = data.template_file.user_data.rendered
  root_block_device {
    volume_type           = "gp2"    # gp2 = general purpose SSD
    volume_size           = "30"
    delete_on_termination = "true"
  }

  depends_on = [aws_iam_role.ecs-instance-role, aws_route_table_association.subnet-public1-association,
                aws_route_table_association.subnet-public2-association, aws_route_table_association.subnet-private1-association,
                aws_route_table_association.subnet-private2-association]

  tags = {
    Name                   = var.ecs-ec2-tag
  }

  lifecycle {
    ignore_changes         = [ami, user_data, subnet_id, key_name, ebs_optimized, private_ip]
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"
}

############################################################
# AWS ECS-TASK DEFINITION
############################################################

resource "aws_ecs_task_definition" "task_definition" {
  container_definitions    = data.template_file.container_definition_json.rendered           # task defination json file location
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn # CHANGE THIS          # role for executing task
  family                   = "simple-php-web"                         # task name
  network_mode             = "awsvpc"                                 # network mode awsvpc, brigde
  memory                   = "256"
  cpu                      = "0.25 vcpu"
  requires_compatibilities = ["EC2"]                                   # Fargate or EC2
  task_role_arn            = aws_iam_role.ecs-task-execution-role.arn  # CHANGE THIS # TASK running role
} 

data "template_file" "container_definition_json" {
  template = "${file("${path.module}/container_definition.json")}"
}

############################################################
# IAM POLICY FOR ECS-INSTANCE-ROLE
############################################################
resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-instance-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-instance-policy.json
}

data "aws_iam_policy_document" "ecs-instance-policy" {
   statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ec2.amazonaws.com"]
  }
 }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
   role = aws_iam_role.ecs-instance-role.name
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

############################################################
# IAM POLICY FOR AWS INSTANCE PROFILE
############################################################
resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ecs-instance-profile"
  path = "/"
  role = aws_iam_role.ecs-instance-role.id
  provisioner "local-exec" {
  command = "sleep 60"
 }
}

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-service-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ecs.amazonaws.com"]
  }
 }
}
############################################################
# IAM POLICY FOR AWS ECS TASK EXECUTION ROLE FOR CREATING TASK DEFINITION
############################################################
resource "aws_iam_role" "ecs-task-execution-role" {
  name  = "belly-ecs-task-execution-role"
  path  = "/"
  assume_role_policy = data.aws_iam_policy_document.trust-relationship-ecs-execution-role.json
}

data "aws_iam_policy_document" "trust-relationship-ecs-execution-role" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ecs-tasks.amazonaws.com"]
  }
 }
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-attachment" {
   role = aws_iam_role.ecs-task-execution-role.name
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
##############################################################
# AWS ECS-SERVICE
##############################################################
resource "aws_ecs_service" "service" {
  cluster                = aws_ecs_cluster.cluster.id                          # ecs cluster id
  desired_count          = 1                                                         # no of task running
  launch_type            = "EC2"                                                     # Cluster type ECS OR FARGATE
  name                   = var.ecs-service-name                                        # Name of service
  task_definition        = aws_ecs_task_definition.task_definition.arn        # Attaching Task to service
  load_balancer {
    container_name       = "simple-php-web"            #"container_${var.component}_${var.environment}"
    container_port       = "80"
    target_group_arn     = aws_lb_target_group.belly-tg-blue.arn  # attaching load_balancer target group to ecs
 }
  network_configuration {
    security_groups       = [aws_security_group.belly-private-instance-sg.id]  #CHANGE THIS
    subnets               = [aws_subnet.belly-subnet-private-1.id, aws_subnet.belly-subnet-private-2.id]  ## Enter the private subnet id
    assign_public_ip      = "false"
  }
  depends_on              = [aws_lb_listener.listener-blue]
}