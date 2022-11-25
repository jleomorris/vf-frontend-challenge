remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = local.environment_tfvars["terraform_bucket"]
    key            = "${local.terragrunt_state_prefix}.${local.environment_tfvars["aws_region"]}.tfstate"
    region         = local.environment_tfvars["terraform_aws_region"]
    encrypt        = true
    dynamodb_table = local.environment_tfvars["terraform_table"]
  }
}

locals {
  terragrunt_state_prefix = try(get_env("TERRAGRUNT_STATE_PREFIX"), "front-end-website.prod")
  terragrunt_identifier = try(get_env("TERRAGRUNT_IDENTIFIER"), "fe")
  terragrunt_aws_region = try(get_env("TERRAGRUNT_AWS_REGION"), "eu-west-2")
  terragrunt_environment = try(get_env("TERRAGRUNT_ENVIRONMENT"), "prod")
  environment_tfvars = jsondecode(file("${get_repo_root()}/iac/terraform_aws/environments/${local.terragrunt_identifier}.${local.terragrunt_environment}.${local.terragrunt_aws_region}.tfvars.json"))
}

inputs = {
  path_from_repo_root = "${get_path_from_repo_root()}"
}

iam_role = local.environment_tfvars["terragrunt_iam_role"]

terraform {

  extra_arguments "common_var" {
    commands  = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=${get_repo_root()}/iac/terraform_aws/environments/${local.terragrunt_identifier}.${local.terragrunt_environment}.${local.terragrunt_aws_region}.tfvars.json"]
  }

  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=20m"]
  }

}
