#################### ALB ####################
resource "aws_alb" "belly-alb" {
  name = var.alb.0
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.belly-alb-sg.id]
  subnets = [aws_subnet.belly-subnet-public-1.id, aws_subnet.belly-subnet-public-2.id]
  tags = {
    Environment  = var.alb.1
  }
}

#################### TARGET GROUP AND LISTENER BLUE ####################
resource "aws_lb_target_group" "belly-tg-blue" {
  name        = var.tg-blue-name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.belly-vpc.id
  deregistration_delay = 60

    health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200-302"
  }
}
#################### TARGET GROUP ATTACHMENT TO SPESIFIC INSTANCE ####################
# # NOTE : kalau ingin scalling, pakai auto scalling group attachment.
# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = aws_lb_target_group.belly-tg-blue.arn
#   target_id        = aws_instance.ec2_instance.id
#   port             = 80
# }

resource "aws_lb_listener" "listener-blue" {
  load_balancer_arn = aws_alb.belly-alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.belly-tg-blue.arn
  }
}

# #################### TARGET GROUP AND LISTENER GREEN ####################
# resource "aws_lb_target_group" "belly-tg-green" {
#   name        = var.tg-green-name
#   port        = 8080
#   protocol    = "HTTP"
#   target_type = "ip"
#   vpc_id      = aws_vpc.belly-vpc
#   deregistration_delay = 60

#     health_check {
#     protocol = "HTTP"
#     path     = "/"
#   }
# }

# resource "aws_lb_listener" "listener-green" {
#   load_balancer_arn = aws_alb.belly-alb.arn
#   port              = "8080"
#   protocol          = "HTTP"
  
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.belly-tg-green.arn
#   }
# }




