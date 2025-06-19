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
# Role que o GitHub Actions vai assumir via OIDC com todas permissões necessárias
##############################
resource "aws_iam_role" "github_app_runner_role" {
  name = "github-app-runner-role"

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
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:eusouodaniel/rocketseat.ci.api:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "full-permissions-for-ecr-and-apprunner"
    policy = jsonencode({
      Version = "2012-10-17"
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
          Resource = "arn:aws:iam::231224359494:role/github-app-runner-role"
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
