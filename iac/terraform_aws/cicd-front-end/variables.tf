#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Environment
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

variable "environment_name" {
  type = string
}

variable "environment_is_branch_based" {
  type = bool
}


variable "is_production_environment" {
  type = bool
}

# AWS

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

# Repository

variable "environment_branch" {
  type = string
}

variable "repository_owner" {
  type        = string
  description = "The owner of the Git repository"
  default     = "visformatics"
}

variable "repository_name" {
  type        = string
  description = "The name of the Git repository"
}

variable "repository_provider" {
  type        = string
  default     = "github"
  description = "The lowercase name of the Git provider, used to form a URI"
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Resource names - only for use when the name is used in multiple places
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

variable "build_base_image_codepipeline_name" {
  type        = string
  default     = "Base-Image"
  description = "The name of the CodePipeline that builds the base image."
}

variable "build_website_codepipeline_name" {
  type        = string
  default     = "Build-Site"
  description = "The name of the CodePipeline that builds the website."
}

variable "deploy_website_codepipeline_name" {
  type        = string
  default     = "Deploy-Site"
  description = "The name of the CodePipeline that deploys the website."
}

variable "build_deploy_website_codepipeline_name" {
  type        = string
  default     = "Website"
  description = "The name of the CodePipeline that builds and deploys the website in lower envs."
}

variable "build_deploy_website_codebuild_name" {
  type        = string
  default     = "Website"
  description = "The name of the CodeBuild that builds and deploys the website in lower envs."
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# File paths - only for use when the path is used in multiple places
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

variable "build_base_image_buildspec_path" {
  type        = string
  default     = "iac/codebuild/simple-shell-script.codebuild.yml"
  description = "The relative path to build-base-image.codebuild.yml from the repository root."
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Terragrunt
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Path of this directory from the root of the Git repository
# Generated via a Terragrunt function
variable "path_from_repo_root" {
  type = string
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Environment branches
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

variable "prod_branch" {
  type        = string
  default     = "main"
  description = "The name of the prod branch."
}

variable "dev_branch" {
  type        = string
  default     = "dev"
  description = "The name of the dev branch."
}

variable "test_branch" {
  type        = string
  default     = "test"
  description = "The name of the test branch."
}

variable "stag_branch" {
  type        = string
  default     = "stag"
  description = "The name of the stag branch."
}
