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
    IAC = true
  }
}

##############################
# Role para o AWS App Runner executar builds e serviços
##############################
resource "aws_iam_role" "app_runner_service_role" {
  name = "app-runner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
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
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]

  tags = {
    IAC = "True"
  }
}

#############################
# Anexar política AWSAppRunnerFullAccess à role de serviço do App Runner
#############################
resource "aws_iam_role_policy_attachment" "app_runner_service_full_access" {
  role       = aws_iam_role.app_runner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppRunnerFullAccess"
}

#########################
# Role que o GitHub Actions vai assumir via OIDC
#############################
resource "aws_iam_role" "app_runner_oidc_role" {
  name = "github-app-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::231224359494:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:eusouodaniel/rocketseat.ci.api:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "ecr-app-permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "Statement1"
          Effect = "Allow"
          Action = "apprunner:*"
          Resource = "*"
        },
        {
          Sid    = "Statement2"
          Effect = "Allow"
          Action = [
            "iam:PassRole",
            "iam:CreateServiceLinkedRole",
          ]
          Resource = "*"
        },
        {
          Sid    = "Statement3"
          Effect = "Allow"
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    IAC = "True"
  }
}
