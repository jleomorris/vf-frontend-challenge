#!/usr/bin/env bash

# Prints the current CodePipeline execution ID. This script is used by other
# scripts in CodePipelines. Originally, the pipeline execution ID was required
# to get the current Git commit.

set -Eeuxo pipefail

# AWS_DEFAULT_REGION: automatically defined by CodePipeline
# CODEBUILD_BUILD_ID: automatically defined by CodePipeline
# THIS_CODEPIPELINE_NAME: the name of the CodePipeline, defined as an environment variable via Terraform

main() {

	pipeline_execution_id=$(aws codepipeline get-pipeline-state --region "${AWS_DEFAULT_REGION}" \
		--name "${THIS_CODEPIPELINE_NAME}" \
		--query 'stageStates[?actionStates[?latestExecution.externalExecutionId==`'${CODEBUILD_BUILD_ID}'`]].latestExecution.pipelineExecutionId' \
		--output text)

	if ! echo "$pipeline_execution_id" | grep -qP '^[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$'; then
		cat <<-EOF
			build-base-image.sh: aws codepipeline
			get-pipeline-state returned an invalid value for
			pipelineExecutionId. Validation rule:
			^.*:[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$.
			Actual value: $pipeline_execution_id.
		EOF
		exit 1
	fi

	echo "$pipeline_execution_id"
}

main "$@"
