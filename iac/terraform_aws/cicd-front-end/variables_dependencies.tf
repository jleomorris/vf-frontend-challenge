#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Dependencies - from other Terraform states.
# Hard coding is the least worst option.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

variable "prod_website_bucket_name" {
  type        = string
  default     = "prod.diamond-medical.health"
  description = "The name of the prod website bucket. NOT a URI or ARN; just the name."
}

variable "prod_cloudfront_distribution_id" {
  type        = string
  default     = "E1NH4XF3TGXEH3"
  description = "The name of the CloudFront distribution ID for prod."
}

variable "prod_cloudfront_distribution_arn" {
  type        = string
  default     = "arn:aws:cloudfront::839764128176:distribution/E1NH4XF3TGXEH3"
  description = "The ARN of the prod CloudFront distribution."
}

variable "dev_website_bucket_name" {
  type        = string
  default     = "dev.diamond-medical.health"
  description = "The name of the dev website bucket. NOT a URI or ARN; just the name."
}

variable "test_website_bucket_name" {
  type        = string
  default     = "test.diamond-medical.health"
  description = "The name of the test website bucket. NOT a URI or ARN; just the name."
}

variable "stag_website_bucket_name" {
  type        = string
  default     = "stag.diamond-medical.health"
  description = "The name of the stag website bucket. NOT a URI or ARN; just the name."
}
