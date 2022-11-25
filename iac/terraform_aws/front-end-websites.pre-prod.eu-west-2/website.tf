module "dev_website" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/s3_website_bucket_with_cloudfront?ref=tags/v2.2.2"

  cors_allowed_headers = ["*"]
  cors_allowed_origins = ["${var.dev_website_hostname}"]
  cors_max_age_seconds = 3600
  cors_allowed_methods = ["GET"]
  hostname             = var.dev_website_hostname
  cache_min_ttl        = 0
  cache_default_ttl    = 0
  cache_max_ttl        = 0
  additional_iam_roles_rw = {
    AllowCodeBuild = var.dev_codebuild_iam_role_arn
  }
}

module "test_website" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/s3_website_bucket_with_cloudfront?ref=tags/v2.2.2"

  cors_allowed_headers = ["*"]
  cors_allowed_origins = ["${var.test_website_hostname}"]
  cors_max_age_seconds = 3600
  cors_allowed_methods = ["GET"]
  hostname             = var.test_website_hostname
  cache_min_ttl        = 0
  cache_default_ttl    = 0
  cache_max_ttl        = 0
  additional_iam_roles_rw = {
    AllowCodeBuild = var.test_codebuild_iam_role_arn
  }
}

module "stag_website" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/s3_website_bucket_with_cloudfront?ref=tags/v2.2.2"

  cors_allowed_headers = ["*"]
  cors_allowed_origins = ["${var.stag_website_hostname}"]
  cors_max_age_seconds = 3600
  cors_allowed_methods = ["GET"]
  hostname             = var.stag_website_hostname
  cache_min_ttl        = 0
  cache_default_ttl    = 0
  cache_max_ttl        = 0
  additional_iam_roles_rw = {
    AllowCodeBuild = var.stag_codebuild_iam_role_arn
  }
}
