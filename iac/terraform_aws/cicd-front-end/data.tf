data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html#IAM_within_account
data "aws_iam_policy_document" "build_base_image_codebuild_extra_permissions" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.base-image.arn]
  }
}

# https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html#IAM_within_account
# https://docs.aws.amazon.com/kms/latest/developerguide/services-parameter-store.html#parameter-store-policies
data "aws_iam_policy_document" "build_website_prod_codebuild_extra_permissions" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]
    resources = [aws_ecr_repository.base-image.arn]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.build-cache.arn]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["${aws_s3_bucket.build-cache.arn}/*"]
  }
  statement {
    actions = ["ssm:GetParameter*"]
    resources = [
      aws_ssm_parameter.prod_dot-env.arn,
      aws_ssm_parameter.brix_deploy_key_private.arn
    ]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values = [
        aws_ssm_parameter.prod_dot-env.arn,
        aws_ssm_parameter.brix_deploy_key_private.arn
      ]
    }
  }
}

data "aws_iam_policy_document" "deploy_website_prod_codebuild_extra_permissions" {
  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.prod_website_bucket_name}",
      "arn:aws:s3:::${module.build-website-pipeline-prod.artifact_bucket_name}"
    ]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["arn:aws:s3:::${var.prod_website_bucket_name}/*"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${module.build-website-pipeline-prod.artifact_bucket_name}/*"]
  }
}

data "aws_iam_policy_document" "build_deploy_website_dev_codebuild_extra_permissions" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]
    resources = [aws_ecr_repository.base-image.arn]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.build-cache.arn]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["${aws_s3_bucket.build-cache.arn}/*"]
  }
  statement {
    actions = ["ssm:GetParameter*"]
    resources = [
      aws_ssm_parameter.dev_dot-env.arn,
      aws_ssm_parameter.brix_deploy_key_private.arn
    ]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values = [
        aws_ssm_parameter.dev_dot-env.arn,
        aws_ssm_parameter.brix_deploy_key_private.arn
      ]
    }
  }
  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.dev_website_bucket_name}"
    ]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["arn:aws:s3:::${var.dev_website_bucket_name}/*"]
  }
}

data "aws_iam_policy_document" "clear_cache_prod_codebuild_extra_permissions" {
  statement {
    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = [var.prod_cloudfront_distribution_arn]
  }
}

data "aws_iam_policy_document" "build_deploy_website_test_codebuild_extra_permissions" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]
    resources = [aws_ecr_repository.base-image.arn]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.build-cache.arn]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["${aws_s3_bucket.build-cache.arn}/*"]
  }
  statement {
    actions = ["ssm:GetParameter*"]
    resources = [
      aws_ssm_parameter.test_dot-env.arn,
      aws_ssm_parameter.brix_deploy_key_private.arn
    ]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values = [
        aws_ssm_parameter.test_dot-env.arn,
        aws_ssm_parameter.brix_deploy_key_private.arn
      ]
    }
  }
  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.test_website_bucket_name}"
    ]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["arn:aws:s3:::${var.test_website_bucket_name}/*"]
  }
}

data "aws_iam_policy_document" "build_deploy_website_stag_codebuild_extra_permissions" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]
    resources = [aws_ecr_repository.base-image.arn]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.build-cache.arn]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["${aws_s3_bucket.build-cache.arn}/*"]
  }
  statement {
    actions = ["ssm:GetParameter*"]
    resources = [
      aws_ssm_parameter.stag_dot-env.arn,
      aws_ssm_parameter.brix_deploy_key_private.arn
    ]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values = [
        aws_ssm_parameter.stag_dot-env.arn,
        aws_ssm_parameter.brix_deploy_key_private.arn
      ]
    }
  }
  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.stag_website_bucket_name}"
    ]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["arn:aws:s3:::${var.stag_website_bucket_name}/*"]
  }
}

data "local_file" "brix_deploy_key_private_file" {
  filename = "./id_github"
}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}
