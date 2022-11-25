#!/usr/bin/env bash

# Prints the first 8 characters of the Git SHA that is currently being run in
# CodePipeline.

set -Eeuxo pipefail

# $1: pipeline_execution_id
# AWS_DEFAULT_REGION: automatically defined by CodePipeline
# THIS_CODEPIPELINE_NAME: the name of the CodePipeline, defined as an environment variable via Terraform

main() {

	GIT_COMMIT_SHA=$(aws codepipeline get-pipeline-execution --region "${AWS_DEFAULT_REGION}" \
		--pipeline-name "${THIS_CODEPIPELINE_NAME}" \
		--pipeline-execution-id "${1}" \
		--query "pipelineExecution.artifactRevisions[?name=='source_output'].revisionId" \
		--output text)

	if ! echo "$GIT_COMMIT_SHA" | grep -qP '^[a-z0-9]{40}$'; then
		cat <<-EOF
			build-base-image.sh: aws codepipeline
			get-pipeline-execution returned an invalid value for
			Git Commit SHA Validation rule: ^[a-z0-9]{40}$. Actual
			value: $GIT_COMMIT_SHA
		EOF
		exit 1
	fi

	echo -n "$GIT_COMMIT_SHA" | cut -c1-8
}

main "$@"
