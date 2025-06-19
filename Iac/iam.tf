##############################
# Provedor OIDC do GitHub Actions para AWS
##############################
resource "aws_iam_openid_connect_provider" "oidc_git" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    IAC = "True"
  }
}

##############################
# Role que o GitHub Actions assume via OIDC
##############################
resource "aws_iam_role" "ecr_role" {
  name = "ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::231224359494:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" = "repo:Francisco1825/rocketseat.ci.api:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "full-permissions-for-ecr-and-apprunner"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid = "AppRunnerPermissions"
          Effect = "Allow"
          Action = [
            "apprunner:*"
          ]
          Resource = "*"
        },
        {
          Sid = "ECRPermissions"
          Effect = "Allow"
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken"
          ]
          Resource = "*"
        },
        {
          Sid = "IAMPassRole"
          Effect = "Allow"
          Action = "iam:PassRole"
          Resource = "*"
        },
        {
          Sid = "IAMCreateServiceLinkedRole"
          Effect = "Allow"
          Action = "iam:CreateServiceLinkedRole"
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    IAC = "True"
  }
}

##############################
# Role que o App Runner usa para acessar o ECR
##############################
resource "aws_iam_role" "app_runner_service_role" {
  name = "app-runner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  tags = {
    IAC = "True"
  }
}
