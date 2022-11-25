#!/usr/bin/env bash

# Generate a CRC checksum that acts as an identifier for the cache. Determined
# by YARN_VERSION, NODE_VERSION, and yarn.lock. If any one of these variables/
# files changes, then the value of the CRC checksum is changed.

# This is used to tag the Docker images that contain the cache and pull the
# right one back down again later.

set -Eeuo pipefail

main() {
	temp_file=$(mktemp)

	echo "YARN_VERSION=$(yarn --version)" >>"$temp_file"
	echo "NODE_VERSION=$(node --version)" >>"$temp_file"
	cksum yarn.lock >>"$temp_file"
	cksum "$temp_file" | cut -f1 -d" "
}

main "$@"
