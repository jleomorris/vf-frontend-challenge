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
# Terragrunt
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Path of this directory from the root of the Git repository
# Generated via a Terragrunt function
variable "path_from_repo_root" {
  type = string
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Websites
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

variable "dev_website_hostname" {
  type        = string
  default     = "dev.diamond-medical.health"
  description = "The hostname of the dev website"
}

variable "stag_website_hostname" {
  type        = string
  default     = "stag.diamond-medical.health"
  description = "The hostname of the stag website"
}

variable "test_website_hostname" {
  type        = string
  default     = "test.diamond-medical.health"
  description = "The hostname of the test website"
}
