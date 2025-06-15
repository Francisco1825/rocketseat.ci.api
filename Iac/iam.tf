##############################
# Provedor OIDC do GitHub Actions para AWS
##############################
resource "aws_iam_openid_connect_provider" "oidc-git" {
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
resource "aws_iam_role" "app-runner-role" {
  name = "app-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid = "AppRunnerTrust",
      Effect = "Allow",
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  tags = {
    IAC = true
  }
}

##############################
# Anexar política AWSAppRunnerFullAccess à role do App Runner
##############################
resource "aws_iam_role_policy_attachment" "app_runner_full_access" {
  role       = aws_iam_role.app-runner-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppRunnerFullAccess"
}

##############################
# Role para o GitHub Actions assumir via OIDC
##############################
resource "aws_iam_role" "github_oidc_role" {
  name = "ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRoleWithWebIdentity",
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc-git.arn
      },
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" = "repo:Francisco1825/rocketseat.ci.api:ref:refs/heads/main"
        }
      }
    }]
  })

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
          Sid = "IAMPassAppRunnerRole",
          Effect = "Allow",
          Action = "iam:PassRole",
          Resource = "arn:aws:iam::231224359494:role/app-runner-role",
          Condition = {
            StringEquals = {
              "iam:PassedToService": "apprunner.amazonaws.com"
            }
          }
        },
        {
          Sid = "CreateSLRForAppRunner",
          Effect = "Allow",
          Action = "iam:CreateServiceLinkedRole",
          Resource = "*",
          Condition = {
            StringEquals = {
              "iam:AWSServiceName": "build.apprunner.amazonaws.com"
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
