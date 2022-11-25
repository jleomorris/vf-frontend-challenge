module "build-website-pipeline-prod" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = true
  repository_name        = var.repository_name
  repository_branch      = var.prod_branch

  # CodePipeline
  codepipeline-name               = "${var.build_website_codepipeline_name}-PROD"
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = false # deploy pipeline needs approval

  # CodeBuild
  codebuild-name                                = "Build-Site-PROD"
  codebuild_buildspec_path                      = "iac/codebuild/one-shell-script.codebuild.yml"
  codebuild_log-group-name                      = "build-site-prod"
  codebuild_iam-role-path                       = "/"
  codebuild_privileged_mode_active              = true
  codebuild_cache-type                          = "LOCAL"
  codebuild_cache-modes                         = ["LOCAL_DOCKER_LAYER_CACHE"]
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.build_website_prod_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_env-vars = {
    CICD_SKIP_TESTS              = "false"
    CICD_IS_PIPELINE             = "true"
    ENVIRONMENT_NAME             = "prod"
    SCRIPT_PATH                  = "cicd/pipeline-wrapper.sh"
    CICD_BULD_SCRIPT_PATH        = "cicd/build.sh"
    BASE_IMAGE_PATH              = aws_ecr_repository.base-image.repository_url
    BRIX_DEPLOY_KEY_PRIVATE_PATH = aws_ssm_parameter.brix_deploy_key_private.name
    ECR_REPOSITORY_REGION        = data.aws_region.current.name
    ECR_REPOSITORY_LOGIN_URL     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    THIS_CODEPIPELINE_NAME       = "${var.build_website_codepipeline_name}-PROD"
    CACHE_BUCKET                 = aws_s3_bucket.build-cache.id
    ENV_SSM_PATH                 = aws_ssm_parameter.prod_dot-env.name
  }
}

module "deploy-website-pipeline-prod" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = false
  repository_name        = var.repository_name
  repository_branch      = var.prod_branch

  # CodePipeline
  codepipeline-name               = "${var.deploy_website_codepipeline_name}-PROD"
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = true

  # CodeBuild
  codebuild-name                                = "Deploy-Site-PROD"
  codebuild_buildspec_path                      = "iac/codebuild/one-shell-script.codebuild.yml"
  codebuild_log-group-name                      = "deploy-site-prod"
  codebuild_iam-role-path                       = "/"
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.deploy_website_prod_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_env-vars = {
    SCRIPT_PATH            = "cicd/deploy.sh"
    CICD_IS_PIPELINE       = "true"
    ENVIRONMENT_NAME       = "prod"
    WEBSITE_BUCKET         = var.prod_website_bucket_name
    BUILD_ARTIFACT_BUCKET  = module.build-website-pipeline-prod.artifact_bucket_name
    THIS_CODEPIPELINE_NAME = "${var.deploy_website_codepipeline_name}-PROD"
  }
}

module "invalidate-cache-pipeline-prod" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = false
  repository_name        = var.repository_name
  repository_branch      = var.prod_branch

  # CodePipeline
  codepipeline-name               = "Clear-Cache-PROD"
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = true

  # CodeBuild
  codebuild-name                                = "Clear-Cache-PROD"
  codebuild_buildspec_path                      = "iac/codebuild/one-shell-script.codebuild.yml"
  codebuild_log-group-name                      = "clear-cache-prod"
  codebuild_iam-role-path                       = "/"
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.clear_cache_prod_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_env-vars = {
    SCRIPT_PATH                = "iac/bash/clear-cloudfront-cache.sh"
    CLOUDFRONT_DISTRIBUTION_ID = var.prod_cloudfront_distribution_id
  }
}

module "build-deploy-website-pipeline-dev" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = true
  repository_name        = var.repository_name
  repository_branch      = var.dev_branch

  # CodePipeline
  codepipeline-name               = "${var.build_deploy_website_codepipeline_name}-DEV"
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = false

  # CodeBuild
  codebuild-name                                = "${var.build_deploy_website_codebuild_name}-DEV"
  codebuild_buildspec_path                      = "iac/codebuild/two-shell-script.codebuild.yml"
  codebuild_log-group-name                      = "${lower(var.build_deploy_website_codebuild_name)}-dev"
  codebuild_iam-role-path                       = "/"
  codebuild_privileged_mode_active              = true
  codebuild_cache-type                          = "LOCAL"
  codebuild_cache-modes                         = ["LOCAL_DOCKER_LAYER_CACHE"]
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.build_deploy_website_dev_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_env-vars = {
    BRIX_DEPLOY_KEY_PRIVATE_PATH = aws_ssm_parameter.brix_deploy_key_private.name
    CICD_SKIP_TESTS              = "false"
    CICD_IS_PIPELINE             = "true"
    ENVIRONMENT_NAME             = "dev"
    SCRIPT_PATH_1                = "cicd/pipeline-wrapper.sh"
    SCRIPT_PATH_2                = "cicd/deploy.sh"
    CICD_BULD_SCRIPT_PATH        = "cicd/build.sh"
    WEBSITE_BUCKET               = var.dev_website_bucket_name
    BASE_IMAGE_PATH              = aws_ecr_repository.base-image.repository_url
    ECR_REPOSITORY_REGION        = data.aws_region.current.name
    ECR_REPOSITORY_LOGIN_URL     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    THIS_CODEPIPELINE_NAME       = "${var.build_deploy_website_codepipeline_name}-DEV"
    CACHE_BUCKET                 = aws_s3_bucket.build-cache.id
    ENV_SSM_PATH                 = aws_ssm_parameter.dev_dot-env.name
  }
}

module "build-deploy-website-pipeline-test" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = true
  repository_name        = var.repository_name
  repository_branch      = var.test_branch

  # CodePipeline
  codepipeline-name               = "${var.build_deploy_website_codepipeline_name}-TEST"
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = false

  # CodeBuild
  codebuild-name                                = "${var.build_deploy_website_codebuild_name}-TEST"
  codebuild_buildspec_path                      = "iac/codebuild/two-shell-script.codebuild.yml"
  codebuild_log-group-name                      = "${lower(var.build_deploy_website_codebuild_name)}-test"
  codebuild_iam-role-path                       = "/"
  codebuild_privileged_mode_active              = true
  codebuild_cache-type                          = "LOCAL"
  codebuild_cache-modes                         = ["LOCAL_DOCKER_LAYER_CACHE"]
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.build_deploy_website_test_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_env-vars = {
    BRIX_DEPLOY_KEY_PRIVATE_PATH = aws_ssm_parameter.brix_deploy_key_private.name
    CICD_SKIP_TESTS              = "false"
    CICD_IS_PIPELINE             = "true"
    ENVIRONMENT_NAME             = "test"
    SCRIPT_PATH_1                = "cicd/pipeline-wrapper.sh"
    SCRIPT_PATH_2                = "cicd/deploy.sh"
    CICD_BULD_SCRIPT_PATH        = "cicd/build.sh"
    WEBSITE_BUCKET               = var.test_website_bucket_name
    BASE_IMAGE_PATH              = aws_ecr_repository.base-image.repository_url
    ECR_REPOSITORY_REGION        = data.aws_region.current.name
    ECR_REPOSITORY_LOGIN_URL     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    THIS_CODEPIPELINE_NAME       = "${var.build_deploy_website_codepipeline_name}-TEST"
    CACHE_BUCKET                 = aws_s3_bucket.build-cache.id
    ENV_SSM_PATH                 = aws_ssm_parameter.test_dot-env.name
  }
}

module "build-deploy-website-pipeline-stag" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = true
  repository_name        = var.repository_name
  repository_branch      = var.stag_branch

  # CodePipeline
  codepipeline-name               = "${var.build_deploy_website_codepipeline_name}-STAG"
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = false

  # CodeBuild
  codebuild-name                                = "${var.build_deploy_website_codebuild_name}-STAG"
  codebuild_buildspec_path                      = "iac/codebuild/two-shell-script.codebuild.yml"
  codebuild_log-group-name                      = "${lower(var.build_deploy_website_codebuild_name)}-stag"
  codebuild_iam-role-path                       = "/"
  codebuild_privileged_mode_active              = true
  codebuild_cache-type                          = "LOCAL"
  codebuild_cache-modes                         = ["LOCAL_DOCKER_LAYER_CACHE"]
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.build_deploy_website_stag_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_env-vars = {
    BRIX_DEPLOY_KEY_PRIVATE_PATH = aws_ssm_parameter.brix_deploy_key_private.name
    CICD_SKIP_TESTS              = "false"
    CICD_IS_PIPELINE             = "true"
    ENVIRONMENT_NAME             = "stag"
    SCRIPT_PATH_1                = "cicd/pipeline-wrapper.sh"
    SCRIPT_PATH_2                = "cicd/deploy.sh"
    CICD_BULD_SCRIPT_PATH        = "cicd/build.sh"
    WEBSITE_BUCKET               = var.stag_website_bucket_name
    BASE_IMAGE_PATH              = aws_ecr_repository.base-image.repository_url
    ECR_REPOSITORY_REGION        = data.aws_region.current.name
    ECR_REPOSITORY_LOGIN_URL     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    THIS_CODEPIPELINE_NAME       = "${var.build_deploy_website_codepipeline_name}-STAG"
    CACHE_BUCKET                 = aws_s3_bucket.build-cache.id
    ENV_SSM_PATH                 = aws_ssm_parameter.stag_dot-env.name
  }
}

module "build-base-image-pipeline" {
  source = "git::git@github.com:visformatics/central_iac.git//terraform/aws/modules/standard_one_stage_codepipeline?ref=tags/v2.0.0"

  source_polling_enabled = false
  repository_name        = var.repository_name
  repository_branch      = var.prod_branch

  # CodePipeline
  codepipeline-name               = var.build_base_image_codepipeline_name
  codepipeline_iam-role-path      = "/"
  codepipeline_has-approval-stage = true

  # CodeBuild
  codebuild-name                                = "Build-Image"
  codebuild_buildspec_path                      = var.build_base_image_buildspec_path
  codebuild_log-group-name                      = "FE-Base-Image"
  codebuild_iam-role-path                       = "/"
  codebuild_iam_additional-permissions_1        = data.aws_iam_policy_document.build_base_image_codebuild_extra_permissions.json
  codebuild_enable_iam_additional-permissions_1 = true
  codebuild_privileged_mode_active              = true
  codebuild_env-vars = {
    NODE_VERSION               = "node_16.x"
    YARN_VERSION               = "1.22.18"
    ECR_REPOSITORY_REGION      = data.aws_region.current.name
    ECR_REPOSITORY_LOGIN_URL   = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    BASE_IMAGE_PATH            = aws_ecr_repository.base-image.repository_url
    BASE_IMAGE_DOCKERFILE_PATH = "iac/dockerfiles/Dockerfile_fe_base-image"
    SCRIPT_PATH                = "iac/bash/build-base-image.sh"
    THIS_CODEPIPELINE_NAME     = var.build_base_image_codepipeline_name
  }
}
