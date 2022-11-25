resource "aws_ssm_parameter" "brix_deploy_key_private" {
  name        = "brix-deploy-key-private"
  description = "The private part of the deploy key for Brix"
  type        = "SecureString"
  value       = data.local_file.brix_deploy_key_private_file.content

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "aws_ssm_parameter" "prod_dot-env" {
  name        = "/prod/dot-env"
  description = "The .env file for building the prod website"
  type        = "SecureString"
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "aws_ssm_parameter" "dev_dot-env" {
  name        = "/dev/dot-env"
  description = "The .env file for building the dev website"
  type        = "SecureString"
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "aws_ssm_parameter" "test_dot-env" {
  name        = "/test/dot-env"
  description = "The .env file for building the test website"
  type        = "SecureString"
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "aws_ssm_parameter" "stag_dot-env" {
  name        = "/stag/dot-env"
  description = "The .env file for building the stag website"
  type        = "SecureString"
  value       = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [ value ]
  }
}
