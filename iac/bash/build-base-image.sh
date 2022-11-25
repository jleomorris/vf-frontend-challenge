#!/usr/bin/env bash

set -Eeuxo pipefail

main() {

	pipeline_execution_id=$(bash iac/bash/print-codepipeline-execution-id.sh)
	echo "pipeline_execution_id=$pipeline_execution_id"

	git_commit_short_sha=$(bash iac/bash/print-codepipeline-active-git-sha.sh "$pipeline_execution_id")
	echo "git_commit_short_sha=$git_commit_short_sha"

	aws ecr get-login-password --region "$ECR_REPOSITORY_REGION" | docker login --username AWS --password-stdin "$ECR_REPOSITORY_LOGIN_URL"

	docker build \
		--no-cache \
		--build-arg NODE_VERSION \
		--build-arg YARN_VERSION \
		-t "$BASE_IMAGE_PATH:$git_commit_short_sha" \
		-t "$BASE_IMAGE_PATH:latest" \
		-t "$BASE_IMAGE_PATH:live" \
		-f "$BASE_IMAGE_DOCKERFILE_PATH" .

	docker push "$BASE_IMAGE_PATH:$git_commit_short_sha" &
	docker push "$BASE_IMAGE_PATH:latest" &
	docker push "$BASE_IMAGE_PATH:live" &
	wait
}


main "$@"
