# -------------------------------------------------------
# ROLE: GitHub Actions (OIDC) - Assume para deploy + push
# -------------------------------------------------------
resource "aws_iam_role" "ecr_role" {
  name = "ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::231224359494:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
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
    name = "ecr-and-apprunner-permissions"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "AppRunnerControl",
          Effect = "Allow",
          Action = [
            "apprunner:ListServices",
            "apprunner:DescribeService",
            "apprunner:CreateService",
            "apprunner:UpdateService",
            "apprunner:PauseService",
            "apprunner:ResumeService",
            "apprunner:DeleteService"
          ],
          Resource = "*"
        },
        {
          Sid    = "ECRAccess",
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
          Sid    = "IAMPassRole",
          Effect = "Allow",
          Action = "iam:PassRole",
          Resource = "arn:aws:iam::231224359494:role/app-runner-service-role"
        },
        {
          Sid    = "IAMCreateServiceLinkedRole",
          Effect = "Allow",
          Action = "iam:CreateServiceLinkedRole",
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    IAC = "True"
  }
}

# -------------------------------------------------------
# ROLE: App Runner - Assume para puxar imagem do ECR
# -------------------------------------------------------
resource "aws_iam_role" "app_runner_service_role" {
  name = "app-runner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apprunner.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "app_runner_ecr_policy" {
  name        = "AppRunnerECRAccessPolicy"
  description = "Policy for App Runner to access ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_ecr_attach" {
  role       = aws_iam_role.app_runner_service_role.name
  policy_arn = aws_iam_policy.app_runner_ecr_policy.arn
}