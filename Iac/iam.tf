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
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:Francisco1825/rocketseat.ci.api:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  inline_policy {
    name   = "ecr-and-apprunner-permissions"
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
