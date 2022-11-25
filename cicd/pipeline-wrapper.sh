#!/usr/bin/env bash

set -Eeuxo pipefail

# Run build.sh in a standard Docker image based on Ubuntu LTS

# Environment variables inserted via Terraform on pipelines. Can also be set
# manually.

main() {
	trap exit_clean_up EXIT

	cache_available="false"
	tmp_cache="$(mktemp -d)" # the path of the cache if it is restored
	insert_dot_env
	insert_brix_deploy_private_key
	authenticate_to_ecr_repository
	set_base_image_tag
	set_cache_id
	set_git_commit_short_sha
	restore_cache_if_exists
	run_build_sh
	save_cache_if_not_restored
	save_build
}

insert_brix_deploy_private_key() {

	aws ssm get-parameter \
		--name "$BRIX_DEPLOY_KEY_PRIVATE_PATH" \
		--output text \
		--with-decryption \
		--query "Parameter.Value" >>iac/res/id_ed25519

	# iac/res/ will get mounted as /root/.ssh/ in the container
	# known hosts is already there

	chmod 400 iac/res/id_ed25519 iac/res/known_hosts
}

insert_dot_env() {
	aws ssm get-parameter \
		--name "$ENV_SSM_PATH" \
		--output text \
		--with-decryption \
		--query "Parameter.Value" >>.env
}

set_base_image_tag() {

	# The tag of the Docker base image that should be used, to prevent live
	# or latest being used and so different commits can use different
	# images.

	base_image_tag="$(jq -r '.base_image_tag' cicd/build-manifest.json)"

	echo "base_image_tag=$base_image_tag"
}

save_build() {
	if [[ -f "$git_commit_short_sha-$ENVIRONMENT_NAME.tar.gz" ]]; then
		aws s3 cp --quiet "$git_commit_short_sha-$ENVIRONMENT_NAME.tar.gz" "s3://$CODEPIPELINE_ARTIFACT_BUCKET/builds/$ENVIRONMENT_NAME/$git_commit_short_sha.tar.gz"
	fi
}

run_build_sh() {
	docker run \
		-v "$PWD:/tmp/build" \
		-v "$tmp_cache/v6:/usr/local/share/.cache/yarn/v6" \
		-v "$PWD/iac/res:/root/.ssh" \
		--workdir "/tmp/build" \
		-e ENVIRONMENT_NAME="$ENVIRONMENT_NAME" \
		-e GIT_COMMIT_SHORT_SHA="$git_commit_short_sha" \
		-e CICD_SKIP_TESTS="$CICD_SKIP_TESTS" \
		-e CICD_IS_PIPELINE="$CICD_IS_PIPELINE" \
		-e CACHE_AVAILABLE="$cache_available" \
		-e CACHE_ID="$cache_id" \
		--entrypoint "/tmp/build/$CICD_BULD_SCRIPT_PATH" \
		"$BASE_IMAGE_PATH:$base_image_tag"
}

save_cache_if_not_restored() {
	if [[ $cache_available == "false" ]] && [[ -f "$cache_id.tar.gz" ]]; then
		aws s3 cp --quiet "$cache_id.tar.gz" "s3://$CACHE_BUCKET/$cache_id.tar.gz"
	fi
}

restore_cache_if_exists() {
	if aws s3 ls "s3://$CACHE_BUCKET/$cache_id.tar.gz"; then
		aws s3 cp --quiet "s3://$CACHE_BUCKET/$cache_id.tar.gz" "$tmp_cache/$cache_id.tar.gz"
		tar -xzf "$tmp_cache/$cache_id.tar.gz" -C "$tmp_cache"
		rm -f "$tmp_cache/$cache_id.tar.gz"
		cache_available="true"
	fi
}

set_git_commit_short_sha() {

	# In the pipelines, get the current Git commit short SHA

	if [[ "${CICD_IS_PIPELINE:-}" == "true" ]]; then
		pipeline_execution_id=$(bash iac/bash/print-codepipeline-execution-id.sh)
		echo "pipeline_execution_id=$pipeline_execution_id"

		git_commit_short_sha=$(bash iac/bash/print-codepipeline-active-git-sha.sh "$pipeline_execution_id")
		echo "git_commit_short_sha=$git_commit_short_sha"
	else
		git_commit_short_sha=echo "$(git rev-parse HEAD)" | cut -c1-8
		echo "git_commit_short_sha=$git_commit_short_sha"
	fi
}

authenticate_to_ecr_repository() {

	# Authenticate with the ECR repository to enable images to be pulled

	aws ecr get-login-password --region "$ECR_REPOSITORY_REGION" | docker login --username AWS --password-stdin "$ECR_REPOSITORY_LOGIN_URL"
}

set_cache_id() {

	# cache_id is a combination of yarn, node, and yarn.lock chksum from
	# within the container. Used to save/restore caches.

	cache_id=$(docker run \
		-v "$PWD:/tmp/build" \
		--workdir /tmp/build \
		--entrypoint /tmp/build/iac/bash/print-cache-cksum.sh \
		"$BASE_IMAGE_PATH:$base_image_tag")

	echo "cache_id=$cache_id"
}

exit_clean_up() {
	rm -rf "$tmp_cache"
}

main "$@"
