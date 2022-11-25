module "website-bucket" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/s3_website_bucket_with_cloudfront?ref=tags/v2.1.0"

  cors_allowed_headers = ["*"]
  cors_allowed_origins = ["${var.website_hostname}"]
  cors_max_age_seconds = 3600
  cors_allowed_methods = ["GET"]
  hostname             = var.website_hostname
  cache_min_ttl        = 0
  cache_default_ttl    = 3600
  cache_max_ttl        = 86400
}
