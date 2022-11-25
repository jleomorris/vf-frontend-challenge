#!/usr/bin/env bash

# The build process in the CI/CD pipelines. This script is designed to be run
# in the pipelines but also locally as a secondary objective (for
# troubleshooting and transparency).

# This is run within an Ubuntu 20:04 container

set -Eeuxo pipefail

# Environment variables inserted via ./pipeline-wrapper.sh. Either they are
# computed in the script itself.

main() {
	if [[ "${CICD_IS_PIPELINE:-}" == "true" ]]; then
		pipeline_only_actions_before_build
	fi

	yarn install --frozen-lockfile

	# Skip tests if the environment variable CICD_SKIP_TESTS is set and
	# true
	if [[ "${CICD_SKIP_TESTS:-}" != "true" ]]; then
		yarn run lint
		yarn run test
	fi

	yarn run prod

	if [[ "${CICD_IS_PIPELINE:-}" == "true" ]]; then
		pipeline_only_actions_after_build
	fi
}

pipeline_only_actions_before_build() {
	set_yarn_cache_location
}

pipeline_only_actions_after_build() {
	create_build_info_file
	archive_and_compress_build
	archive_and_compress_cache
}

set_yarn_cache_location() {
	mkdir -p /usr/local/share/.cache/yarn/v6
	yarn config set cache-folder /usr/local/share/.cache/yarn/v6
}

archive_and_compress_cache() {
	if [[ $CACHE_AVAILABLE == "false" ]]; then
		tar --use-compress-program="pigz -k " -cf "$CACHE_ID.tar.gz" -C /usr/local/share/.cache/yarn/v6 .
	fi
}

archive_and_compress_build() {
	tar --use-compress-program="pigz -k " -cf "$GIT_COMMIT_SHORT_SHA-$ENVIRONMENT_NAME.tar.gz" -C dist/ .
}

create_build_info_file() {

	# A build-info text file at the root of the build containing useful
	# metadata

	echo "GIT_SHA=$GIT_COMMIT_SHORT_SHA" >>dist/build-info
}

main "$@"
