#!/usr/bin/env bash

set -Eeuxo pipefail

main() {
	trap exit_clean_up EXIT
	set_commit_to_deploy
	process_commit_to_deploy_set_git_commit_short_sha
	tmp_dir="$(mktemp -d)"
	unarchived_files="$tmp_dir/unarchived_files"
	mkdir -p "$unarchived_files"
	set_build_archive_path
	if aws s3 ls "$build_archive_path"; then
		fetch_build_archive
		extract_build_archive
		clear_website_bucket
		move_extracted_build_to_website_bucket
	else
		error_build_doesnt_exist
	fi
}

set_build_archive_path() {

	# In pre-prod environments there is only pipeline, so we just use the
	# current artifact bucket

	if [[ "$ENVIRONMENT_NAME" == "prod" ]]; then
		build_archive_path="s3://$BUILD_ARTIFACT_BUCKET/builds/$ENVIRONMENT_NAME/$git_commit_short_sha.tar.gz"
	else
		build_archive_path="s3://$CODEPIPELINE_ARTIFACT_BUCKET/builds/$ENVIRONMENT_NAME/$git_commit_short_sha.tar.gz"
	fi
}

error_build_doesnt_exist() {
	cat <<-EOF >>/dev/stderr
		CRITICAL: the build for $git_commit_short_sha does not
		exist at $build_archive_path.

		Possibilities:
			- Incorrect .commit_to_deploy in cicd/build-manifest.json.
			- The build pipeline hasn't run yet.
			- A bug in the shell scripts.
	EOF
	sleep 2 # stop the build exiting too fast that this error
	# doesn't appear
	exit 1
}

move_extracted_build_to_website_bucket() {
	aws s3 cp --quiet --recursive "$unarchived_files/" "s3://$WEBSITE_BUCKET"
}

clear_website_bucket() {
	aws s3 rm --quiet "s3://$WEBSITE_BUCKET" --recursive
}

fetch_build_archive() {
	aws s3 cp --quiet "$build_archive_path" "$tmp_dir/$git_commit_short_sha.tar.gz"
}

extract_build_archive() {
	tar -xzvf "$tmp_dir/$git_commit_short_sha.tar.gz" -C "$unarchived_files"
}

set_commit_to_deploy() {
	commit_to_deploy="$(jq -r '.commit_to_deploy' cicd/build-manifest.json)"
	echo "commit_to_deploy=$commit_to_deploy"
}

process_commit_to_deploy_set_git_commit_short_sha() {
	if [[ "$commit_to_deploy" == "latest" ]]; then
		get_latest_git_commit_short_sha
	else
		git_commit_short_sha="$commit_to_deploy"
	fi
}

get_latest_git_commit_short_sha() {

	# In the pipelines, get the current Git commit short SHA

	if [[ "${CICD_IS_PIPELINE:-}" == "true" ]]; then
		pipeline_execution_id=$(bash iac/bash/print-codepipeline-execution-id.sh)
		echo "pipeline_execution_id=$pipeline_execution_id"

		git_commit_short_sha=$(bash iac/bash/print-codepipeline-active-git-sha.sh "$pipeline_execution_id")
		echo "git_commit_short_sha=$git_commit_short_sha"
	else
		git_commit_short_sha=$(echo "$(git rev-parse HEAD)" | cut -c1-8)
		echo "git_commit_short_sha=$git_commit_short_sha"
	fi
}

exit_clean_up() {
	rm -rf "$tmp_dir"
}

main "$@"
