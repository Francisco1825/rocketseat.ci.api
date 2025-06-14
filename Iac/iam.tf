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

resource "aws_iam_role" "ecr-role" {
  name = "ecr-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": aws_iam_openid_connect_provider.oidc-git.arn
        },
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": [
              "sts.amazonaws.com"
            ],
            "token.actions.githubusercontent.com:sub": [
              "repo:Francisco1825/rocketseat.ci.api:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })

  inline_policy {
    name = "ecr-app-permission"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid      = "Statement1"
          Effect   = "Allow"
          Action   = [
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
        }
      ]
    })
  }

  tags = {
    IAC = true
  }
}
