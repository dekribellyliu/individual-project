# FOR SOURCE CODE
provider "github" {
  token        = var.github_token
}

################ S3 ################
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3-bucket
  acl    = "private"

  versioning {
    enabled = true
  }
}
############################################################
# CODE BUILD
############################################################

# CREATE IAM POLICY AND ROLE
resource "aws_iam_role" "belly-codebuild-role" {
  name = var.codebuild-name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "belly-codebuild-policy" {
  role = aws_iam_role.belly-codebuild-role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"

      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "${aws_subnet.belly-subnet-private-1.arn}",
            "${aws_subnet.belly-subnet-private-2.arn}",
            "${aws_subnet.belly-subnet-public-1.arn}",
            "${aws_subnet.belly-subnet-public-2.arn}"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
            "Effect": "Allow", 
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcs"
            ], 
            "Resource": "*" 
        },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*" 
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.s3_bucket.arn}",
        "${aws_s3_bucket.s3_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "build_project" {
    
    name = var.codebuild-project-name
    service_role  = aws_iam_role.belly-codebuild-role.arn
    build_timeout = 60
    
    artifacts {
        type = "CODEPIPELINE"
    }
    
    environment {
        compute_type = "BUILD_GENERAL1_MEDIUM"
        image = "aws/codebuild/standard:2.0"
        type = "LINUX_CONTAINER"
        privileged_mode = true

          environment_variable {
          name  = "TASK_DEFINITION"
          value = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.task_definition.family}"
          }
    }
    
    # cache {
    #     type = "LOCAL"
    #     modes = [
    #         "LOCAL_CUSTOM_CACHE",
   	#     "LOCAL_DOCKER_LAYER_CACHE",
    #         "LOCAL_SOURCE_CACHE"
    #     ]
    # }
    
    source {
        type      = "CODEPIPELINE"
        buildspec = "buildspec.yml"
    }

    vpc_config {
      vpc_id = aws_vpc.belly-vpc.id
      subnets = [aws_subnet.belly-subnet-private-1.id, aws_subnet.belly-subnet-private-2.id]
      security_group_ids = [aws_security_group.belly-private-instance-sg.id]
    }
}

# ############################################################
# # CODE DEPLOY
# ############################################################

# # CREATE IAM POLICY AND ROLE CODE DEPLOY
# resource "aws_iam_role" "codedeploy" {
#   name = var.deploy-role

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "codedeploy.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
#   role       = aws_iam_role.codedeploy.name
# }

# # DEPLOY

# resource "aws_codedeploy_app" "deploy-app" {
#   compute_platform = "ECS"
#   name             = var.deploy-app-name
# }

# resource "aws_codedeploy_deployment_group" "deploy-group" {
#   app_name               = aws_codedeploy_app.deploy-app.name
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
#   deployment_group_name  = var.deploy-group-name
#   service_role_arn       = aws_iam_role.codedeploy.arn

#     auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }

#     deployment_style {
#     deployment_option = "WITHOUT_TRAFFIC_CONTROL"
#     deployment_type   = "IN_PLACE"
#   }

#   ecs_service {
#     cluster_name = aws_ecs_cluster.cluster.name
#     service_name = aws_ecs_service.service.name
#   }

#   load_balancer_info {
#     target_group_pair_info {
#       prod_traffic_route {
#         listener_arns = [aws_lb_listener.listener-blue.arn]
#       }

#       target_group {
#         name = var.tg-blue-name
#       }
#   }
# }
# }

############################################################
# CODE PIPELINE
############################################################

# CREATE IAM POLICY AND ROLE CODEPIPELINE
resource "aws_iam_role" "codepipeline_role" {
  name = var.codepipeline-role

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": 
          "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = var.codepipeline-policy
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "ecs:*",
        "ec2:*",
        "iam:PassRole",
        "iam:PassedToService"
      ],
      "Resource": "*"
    }

  ]
}
EOF
}


resource "aws_codepipeline" "standard_codepipeline" {
  name       = var.codepipeline-name
  role_arn   = aws_iam_role.codepipeline_role.arn
  depends_on = [aws_codebuild_project.build_project]

  artifact_store {
    location = aws_s3_bucket.s3_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_artifact"]

      configuration = {
        Owner       = var.github_username
        OAuthToken  = var.github_token
        Repo        = var.github_repo
        Branch      = var.github_branch
      } 
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_artifact"]
      output_artifacts = ["build_artifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_artifact"]
      version         = "1"

      configuration = {
        ClusterName = var.cluster-name
        ServiceName = var.ecs-service-name
        FileName    = "updateTask.json"

      }
    }
  }
}

