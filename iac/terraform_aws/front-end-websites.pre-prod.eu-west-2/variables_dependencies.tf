variable "dev_codebuild_iam_role_arn" {
  type        = string
  default     = "arn:aws:iam::839764128176:role/Website-DEV_CodeBuild_eu-west-2_IAM-Role"
  description = "The ARN of the CodeBuild IAM Role that performs the dev build"
}

variable "test_codebuild_iam_role_arn" {
  type        = string
  default     = "arn:aws:iam::839764128176:role/Website-TEST_CodeBuild_eu-west-2_IAM-Role"
  description = "The ARN of the CodeBuild IAM Role that performs the test build"
}

variable "stag_codebuild_iam_role_arn" {
  type        = string
  default     = "arn:aws:iam::839764128176:role/Website-STAG_CodeBuild_eu-west-2_IAM-Role"
  description = "The ARN of the CodeBuild IAM Role that performs the stag build"
}
