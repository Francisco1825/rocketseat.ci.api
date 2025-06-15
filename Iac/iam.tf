##############################
# Provedor OIDC do GitHub Actions para AWS
##############################
resource "aws_iam_openid_connect_provider" "oidc-git" {
  # URL do provedor OIDC do GitHub Actions
  url = "https://token.actions.githubusercontent.com"

  # Lista de clientes que podem usar o token para assumir a role (STS)
  client_id_list = [
    "sts.amazonaws.com"
  ]

  # Thumbprint da autoridade certificadora para segurança HTTPS
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
resource "aws_iam_role" "app-runner-role" {
  name = "app-runner-role"

  # Política de confiança que permite o serviço App Runner assumir esta role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AppRunnerTrust",
        Effect = "Allow",
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Permissão gerenciada para ler imagens do ECR
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  tags = {
    IAC = true
  }
}

##############################
# Role para o GitHub Actions assumir via OIDC e acessar ECR e App Runner
##############################
resource "aws_iam_role" "github_oidc_role" {
  name = "ecr-role"

  # Política de confiança que permite assumir a role via Web Identity Token do GitHub Actions
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc-git.arn
        },
        Condition = {
          StringEquals = {
            # Valida o público do token (audience)
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
            # Restringe a role ao repositório e branch específicos do GitHub
            "token.actions.githubusercontent.com:sub" = "repo:Francisco1825/rocketseat.ci.api:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  # Política inline com permissões específicas para ECR, App Runner e IAM
  inline_policy {
    name = "ecr-app-runner-policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid = "ECRAccess",
          Effect = "Allow",
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken"
          ],
          Resource = "*"
        },
        {
          Sid = "AppRunnerAccess",
          Effect = "Allow",
          Action = [
            "apprunner:CreateService",
            "apprunner:UpdateService",
            "apprunner:DescribeService",
            "apprunner:DeleteService",
            "apprunner:PauseService",
            "apprunner:ResumeService",
            "apprunner:List*"
          ],
          Resource = "*"
        },
        {
          Sid = "IAMPermissions",
          Effect = "Allow",
          Action = [
            "iam:PassRole",
            "iam:CreateServiceLinkedRole"
          ],
          Resource = "*",
          Condition = {
            StringEqualsIfExists = {
              # Restrição para criação de Service Linked Role específica do App Runner
              "iam:AWSServiceName" = "build.apprunner.amazonaws.com"
            }
          }
        }
      ]
    })
  }

  tags = {
    IAC = true
  }
}
