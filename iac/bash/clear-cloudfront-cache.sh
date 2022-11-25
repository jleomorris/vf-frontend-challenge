#!/usr/bin/env bash

set -Eeuxo pipefail

main() {
	aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" --paths "/*"
}

main "$@"
