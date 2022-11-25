# Documentation

## Overview of infrastructure as code (IaC) and CI/CD 

This repository contains infrastructure as code for production and
pre-production S3 website buckets behind CloudFront distributions, along with
the CI/CD pipelines to automate the deployment of code.

All resources are created and managed via Terraform with the Terragrunt wrapper.

All pipelines use AWS CodePipeline and CodeBuild and are contained within the
production environment. The pipelines exist in the production account because
they need to share a common cache for deterministic builds and it is better to
demote from a higher trust zone than promote to it. Additionally, a Docker image
(based on Ubuntu) is shared between the pipelines.

The pipelines are branched based. Pipelines for lower environments trigger
automatically when a new change is pushed to GitHub. Currently:

Branch 	Environment
main 	production
dev 	development
stag    staging
test 	testing

Environment branches except production are designed to be short-lived and
blowing them away on a regular basic is encouraged; provided there are no
changes to the IaC codebase that first need to be reconciled.

A second pre-production account contains the buckets and CloudFront
distributions (CDN) for dev, test, and stag. The production bucket and
CloudFront distribution is contained within the production account.

The lower environments do not have caching enabled on the CloudFront
distribution as it is unnecessary and invalidation proved difficult to implement
across accounts.

The lower environment pipelines are currently named `Website-ENV` and there is
only a single pipeline for each. Nevertheless, the pipelines call exactly the
same Bash scripts (the pipeline logic) as the production pipeline, bar the cache
invalidation script.

There are three pipelines for production:

```
Build-Site-PROD
Deploy-Site-PROD
Clear-Cache-PROD
```

- Build-Site-PROD runs the yarn build process and produces tar.gz archive
  containing the result and is stored in the pipelines artifact bucket.

  Build occurs automatically whenever anything is pushed to GitHub.

- Deploy-Site-PROD extracts the tar.gz archive in the artifact bucket, clears
  the website bucket of contents, and then deploys the contents of the tar.gz
  archive to the bucket. There is some additional logic involving
  build-manifest.json explained in the rollback section.

  Deploy should be called manually once the build pipeline is finished. It has
  an approval stage as a security measure.

- Clear-Cache-PROD clears the CloudFront (CDN) cache. This pipeline should be
  called last and manually after deploy. It is a separate pipeline because:

  1) To allow confirmation that a successful production has occurred.

  2) To allow leeway for problems if a problem occurs during deploy.

  3) To allow for manual clears easily outside of a deploy.

  Clear cache also has an approval stage for security/safety reasons.

.env files for each environment live in SSM parameter store and are inserted at
build time. Each build tar.gz archive contains the .env as it was during that
specific build. If .env is changed, it is important to clear all the builds from
artifact buckets. However, do not clear the cache bucket as it is unnecessary
and we would lose the ability to re-create builds deterministically. 

The Base-Image pipeline creates an Ubuntu Docker image with a tag corresponding
to the current short Git commit SHA. Node, Yarn, the AWS CLI, and some software
used in the pipelines is installed here. This pipeline exists for a few reasons:

- NodeJS and Yarn versions need changing infrequently yet add substantially to
  the build time of every commit.

- To provide a consistent common environment for builds across pipelines/cloud
  providers and enable replication on localhost for troubleshooting.

Once an image is created, it is pushed to an ECR (Docker) repository, where it
is used in each of the build pipelines. The pipeline is called manually and
should be called infrequently.

Generally the "live" image tag is used in pipelines, however, manipulation of
build-manifest.json can alter this.

## CI/CD pipeline workflow summary

- If the `Base-Image` pipeline has never been run, run it to create a Docker
  base image.

- In pre-production environments, the `Website-ENV` pipelines are the complete
  CI/CD pipeline and work trigger automatically on push to the appropriate
  branch. No further itervention is necessary. They can be manually triggered if
  necessary.

- In production, `Build-Site-PROD` occurs automatically on a push to main. After
  that finishes, run `Deploy-Site-PROD` manually. When happy the deployment
  occured successful, run `Clear-Cache-PROD` manually.

## Tree view

```
ROOT
├── cicd
│   ├── build-manifest.json
│   ├── build.sh
│   ├── deploy.sh
│   └── pipeline-wrapper.sh
├── iac
│   ├── bash
│   │   ├── base-image-configuration.sh
│   │   ├── build-base-image.sh
│   │   ├── clear-cloudfront-cache.sh
│   │   ├── print-cache-cksum.sh
│   │   ├── print-codepipeline-active-git-sha.sh
│   │   └── print-codepipeline-execution-id.sh
│   ├── codebuild
│   │   ├── one-shell-script.codebuild.yml
│   │   └── two-shell-script.codebuild.yml
│   ├── dockerfiles
│   │   └── Dockerfile_fe_base-image
│   ├── README.md
│   ├── res
│   │   ├── aws.gpg.key
│   │   ├── known_hosts
│   │   └── nodesource.gpg.key
│   └── terraform_aws
│       ├── cicd-front-end
│       │   ├── data.tf
│       │   ├── ecr.tf
│       │   ├── eu-west-2
│       │   │   └── terragrunt.hcl
│       │   ├── id_github
│       │   ├── id_github.pub
│       │   ├── locals.tf
│       │   ├── pipelines.tf
│       │   ├── s3.tf
│       │   ├── ssm_parameter-store.tf
│       │   ├── terraform.tf
│       │   ├── variables_dependencies.tf
│       │   └── variables.tf
│       ├── environments
│       │   ├── fe.pre-prod.eu-west-2.tfvars.json
│       │   └── fe.prod.eu-west-2.tfvars.json
│       ├── front-end-website.prod.eu-west-2
│       │   ├── locals.tf
│       │   ├── terraform.tf
│       │   ├── terragrunt.hcl
│       │   ├── variables.tf
│       │   └── website.tf
│       ├── front-end-websites.pre-prod.eu-west-2
│       │   ├── locals.tf
│       │   ├── terraform.tf
│       │   ├── terragrunt.hcl
│       │   ├── variables.tf
│       │   ├── variables_dependencies.tf
│       │   └── website.tf
│       └── Makefile
```

## Deployment to a new repository

0. Have both an appropriate version of Terraform (check a Terraform.tf
   installed) and the latest version of Terragrunt.

1. Copy both the root `cicd` and `iac` directories to the repository.

2. Change the `tfvars` files with the metadata for the environments.

   If you are re-using accounts there will be naming conflicts and things will
   need renaming more widely.

3. Change the vales in the variables_dependencies.tf files appropriately for the
   accounts or insert placeholder data (and run terragrunt apply multiple
   times).

4. Rename directories to the appropriate region if this is different to
   eu-west-2.

5. cd to the `front-end-website.prod.eu-west-2` directory. Run `terragrunt apply`.

6. cd to the `front-end-websites.pre-prod.eu-west-2` directory. Run `terragrunt apply`.

7. cd to the `cicd-front-end/eu-west-2` directory. Run `terragrunt apply`.

8. If you inserted placeholder data, find out what the actual data is and
   `terragrunt apply` again.

9. Go to CodePipeline. On the left that is `Settings > Connections`. Each
   connection manually needs authorizing with GitHub.

10. Run the `Base-Image` pipeline.

11. Ready for the normal CI/CD process.

## CI/CD in-detail

Please read the overview first.

```
ROOT
├── cicd
│   ├── build-manifest.json
│   ├── build.sh
│   ├── deploy.sh
│   └── pipeline-wrapper.sh
├── iac
│   ├── bash
│   │   ├── base-image-configuration.sh
│   │   ├── build-base-image.sh
│   │   ├── clear-cloudfront-cache.sh
│   │   ├── print-cache-cksum.sh
│   │   ├── print-codepipeline-active-git-sha.sh
│   │   └── print-codepipeline-execution-id.sh
│   ├── codebuild
│   │   ├── one-shell-script.codebuild.yml
│   │   └── two-shell-script.codebuild.yml
│   ├── dockerfiles
│   │   └── Dockerfile_fe_base-image
│   ├── res
│   │   ├── aws.gpg.key
│   │   ├── known_hosts
│   │   └── nodesource.gpg.key
```

The `cicd` directory is intended to control the main logic of the pipelines and
make it accessible for developers to access.

`build.sh` contains the standard yarn build process as documented in the
`../README.md` managed by the front-end team. `build.sh` occurs inside the
standard Docker container. This is essentially the logic of `Build-Site-PROD`
pipeline.

`pipeline-wrapper` wraps `build.sh`, calling it using Docker run, sets up the
environment for `build.sh` and stores artifacts.

`deploy.sh` fetches the build archive from the archive bucket, extracts it,
clears the website bucket, and then deploys the files extracted to the website
bucket. This is essentially the logic of `Deploy-Site-PROD` pipeline.

Pre-production pipelines call both `build.sh` and then `deploy.sh`.

`build-manifest` is discussed in-detail in the rolling back section.

The `iac/bash` directory contains more shell scripts that are called in the
pipelines that are more specialist and developers will perhaps be less
interested in. 

`clear-cloudfront-cache.sh` is as the name suggests. This is essentially the
logic of `Clear-Cache-PROD` pipeline.

`build-base-image.sh` calls `dockerfiles/Dockerfile_fe_base-image` which calls
`base-image-configuration.sh`. Almost all the logic is in the latter script
rather than the Dockerfile. This is essentially the logic of the `Base-Image`
pipeline.

The `print-*` files are helper scripts called by all the build pipelines.

`print-cache-cksum.sh` creates an identifier (CRC checksum) for a cache archive
that is based on the current version of NodeJS, yarn, and the yarn.lock in the
repository. It is used to save and restore the right yarn cache, which gives us
deterministic (and much faster) builds.

There is no good mechanism for identifying the current Git SHA being processed
in the pipeline; so this is what `print-codepipeline-execution-id.sh` and
`print-codepipeline-active-git-sha.sh` are for. The latter script is the end
goal but requires a pipeline execution id in order to function.

### CodeBuild files

CodeBuild files only call one or two shell scripts. They are re-used for
multiple pipelines. The shell scripts called are defined as environment
variables via Terraform.

CodeBuild has been avoided in favour of shell scripts to make the process more
cloud provider agnostic and avoid long complicated YAML files.

### res

res contains static resources. `aws.gpg.key` and `nodesource.gpg.key` are used
in the `Build-Image` pipeline to install the AWS CLI and NodeJS securely.

`known_hosts` contains the SSH known_hosts id_ed25519 signature for GitHub. This
enables Brix to be pulled from the GitHub private repository using a deploy key.

res is mounted as `/root/.ssh` inside the Docker image when `build.ssh` is run.

## Rolling back prod and using a specific Docker image build

`cicd/manifest.json` enables some features if edited appropriately. 

If a valid tag (based on the first characters of the Git SHA; check in ECR) is
put inserted as the value for `base_image_tag`, this image will be used for
builds in whatever environment the current branch corresponds to. In other
words, the NodeJS and Yarn version will be fixed. I recommend the front-end
community utilize this feature.

`commit_to_deploy` enables fast roll backs of production. Simply change this to
the first 8 characters of the Git SHA of the previous build (must exist in
artifact bucket) you want to roll back to, commit/push to the appropriate
branch, then re-run `Deploy-Site-PROD` and `Clear-Cache-PROD`. This
functionality should be used sparingly and reverted to latest once the build is
fixed; if left the deploy pipeline will always deploy that specific Git SHA.

```
{
  "base_image_tag": "latest",
  "commit_to_deploy": "latest"
}
```

## Artifacts and buckets

There is an S3 artifact bucket for each pipeline (there has to be), however, not
every bucket is important. Each bucket has a lifecycle policy on that expires
the default artifacts that CodePipeline spits out - these are useless and have a
cost; they will appear under a path that looks like the first 20 characters of
the pipeline name. Lifecycle policies only trigger once per day so you might see
some occasionally.

Pre-production build artifacts live in buckets with the following naming
convention/path:

```
website-ENV-codepipeline-REGION-artifact-bucket/builds/ENV/SHORT_GIT_SHA.tar.gz
```

Production build artifacts live in buckets with the following naming
convention/path:

```
build-site-prod-codepipeline-REGION-artifact-bucket/builds/prod/SHORT_GIT_SHA.tar.gz
```

The yarn caches artifacts live in buckets with the following naming
convention/path:

```
build-website-pipeline-cache-REGION
```

It is important that these artifacts are retained or builds will not be
deterministic.

Each account has a Terraform state bucket created by Terragrunt. This should
never be deleted and has versioning enabled. A DynamoDB table controls Terraform
locks. It is safe to clear items out of this table when necessary, provided you
have confirmed no one else is using Terraform.

## IaC in-detail

```
ROOT
├── iac
│   └── terraform_aws
│       ├── cicd-front-end
│       │   ├── data.tf
│       │   ├── ecr.tf
│       │   ├── eu-west-2
│       │   │   └── terragrunt.hcl
│       │   ├── id_github
│       │   ├── id_github.pub
│       │   ├── locals.tf
│       │   ├── pipelines.tf
│       │   ├── s3.tf
│       │   ├── ssm_parameter-store.tf
│       │   ├── terraform.tf
│       │   └── variables.tf
│       ├── environments
│       │   ├── fe.pre-prod.eu-west-2.tfvars.json
│       │   └── fe.prod.eu-west-2.tfvars.json
│       ├── front-end-website.prod.eu-west-2
│       │   ├── locals.tf
│       │   ├── terraform.tf
│       │   ├── terragrunt.hcl
│       │   ├── variables.tf
│       │   └── website.tf
│       ├── front-end-websites.pre-prod.eu-west-2
│       │   ├── locals.tf
│       │   ├── terraform.tf
│       │   ├── terragrunt.hcl
│       │   ├── variables.tf
│       │   └── website.tf
│       └── Makefile
```

### Terraform directories

- `cicd-front-end` contains definitions for all CI/CD pipelines (and their
  buckets), the S3 cache bucket, the ECR repository, and SSM parameters for the .env
  files/Brix private key.

- `front-end-website.prod.eu-west-2` contains the definition for the production
  S3 bucket and CloudFront distribution. This has been split to have separate
  Terraform state. This means everything else except this could be destroyed, if
  need be, as this is the only truly important customer-facing state.

- `front-end-websites.pre-prod.eu-west-2` contains the definition for
  pre-production S3 buckets and CloudFront distributions.

### Environments

The `tfvars.json` files contain environment (account) specific information, such
as account numbers, names, and Terraform buckets. One `tfvars.json` may be used
by many Terraform states.

Terragrunt uses some of these variables in terragrunt.hcl to determine Terraform
state buckets, paths, and lock tables.

All these variables are passed to Terraform such that they can be used for
functionality such as tagging or naming.

Part of the reason for these files existing is to enable someone to find
resources by reading the repository.

### Modules

All Terraform directories use external modules defined in the GitHub repository
`visformatics/central_iac`. In order to deploy the Terraform you will need a
valid SSH key and access to this repository. 

If modules are changed in `central_iac` and the change needs to be reflected
here, create a new Git tag in `central_iac` and change the version on the
module. `terragrunt init` will need running afterwards.

### Makefile

The Makefile in `terraform_aws` has some shortcuts for commands that are
occasionally necessary.

Occasionally, Terraform thinks there is a state migration problem and needs to
b reconfigure with `make reconfigure`.

Run `make remove-local-state` and `make clear-terragrunt-cache` when in the
`terraform_aws` directory to clear up after previous builds.

### Dependencies

There are dependencies between the different Terraform directories, although
this could be overcome by inserting dummy data.

`front-end-website.prod.eu-west-2` has no dependencies and should be deployed
first.

`front-end-websites.pre-prod.eu-west-2` has some dependencies on resource names
created in `cicd-front-end`. See variables_dependencies.tf. Insert dummy data or
work out what the ARN will be (it is predictable). This is recommended to be
deployed next.

`cicd-front-end` has dependencies on `front-end-websites.pre-prod.eu-west-2`,
documented in variables_dependencies.tf. As this has the most complicated
dependencies, it is recommended to be deployed last.

Terragrunt has the ability to work out dependencies trees and insert/output from
each Terraform state (directory). However, Terraform does not have this feature
and I decided not to commit to it to Terragrunt to this extent.

## Terragrunt in-detail

Terragrunt is a wrapper for Terraform, and is used to add some extra very useful
functionality.

All Terraform flags passed to Terragrunt will be passed to Terraform (e.g.
terragrunt apply would be passed as terraform apply).

Terragrunt behaviour is defined in a terragrunt.hcl file. Each directory with a
terragrunt.hcl file above is a distinct installation of Terraform and has distinct
state. 

The directory names are not important at all, they are merely a sensible
convention for communicating intent.

Wherever the terragrunt.hcl file is is where you need to run terragrunt commands
from.

A typical terragrunt.hcl file might look like this:

```
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

iam_role = "arn:aws:iam::839764128176:role/terragrunt"

terraform {

  source = "..//."

  extra_arguments "common_var" {
    commands  = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=${get_repo_root()}/iac/terraform_aws/environments/${local.terragrunt_identifier}.${local.terragrunt_environment}.${local.terragrunt_aws_region}.tfvars.json"]
  }

  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=20m"]
  }

}
```

The `backend.tf` specifies the Terraform remote state backend. This file is generated
via Terragrunt as per the generate block. `backend.tf` is in .gitignore.

The config block specifies the remote bucket, key (path) of state,
dynamodb lock table, and region of using the locals block. Locals are the
Terraform equivalent to variables in your standard C-like language (what
Terraform calls variables are actually arguments in C-like arguments). Most of
the values in locals come from the `tfvars.json` files in `environments`.

The middle three values in locals are used to lookup the correct `environments`
file.

`terragrunt_state_prefix` is the prefix of the state file in the Terraform state
bucket - allowing many states to exist in the same bucket with unique names.

`terragrunt_aws_region` enables Terraform to deploy resources to regions other
than the region it is currently in, therefore enabling multi-region deployments
and pipelines (potentially but not currently).

All locals can be overridden if a specific environment variable is set. This is
intended to allow the code to be very flexible and allow creation of
emergency/ad hoc environments quickly, without modification to the codebase. If
no environment variables are set, the fallback hard-coded value is used, which
it should probably be in the majority of cases.

`path_from_repo_root` becomes a default tag on resources and is intended to help
match resources to code quickly.

`iam_role` is the AWS IAM role that Terragrunt will assume when deploying
infrastructure. This enables infrastructure to be deployed to multiple accounts
with a single command.

The `source` in the Terraform block enables Terraform code to be copied around
the directory structure to avoid repetition. In order to prevent complex
codebases, it is important to use this sensibly. Only use this to enable
multi-region deployments of the same codebase (see `cicd-front-end` for an
example). The rule: Terraform must exist one directory below terraform_aws and
the maximum depth of a terragrunt.hcl is one directory below that (for each
region).

This will create a .terragrunt-cache in the directory that is advisable to clean
using the Makefile shortcuts.

Extra arguments blocks add the correct `environments` `tfvars.json` file to the
Terraform command automatically and retry the Terraform lock for 20 mins.

Terragrunt can also run a plan/apply on every bit of Terraform at once: 
https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/

## TODO

- At the time of writing domain names are not yet determined for Diamond (the
  first use of this code), so I have not yet been able to add DNS records to the
  CloudFront distributions.
