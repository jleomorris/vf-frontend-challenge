#!/usr/bin/env bash

set -Eeuxo pipefail

STARTING_DIR=$(pwd)

NODESOURCE_GPG_KEY_PATH="$1"
AWS_GPG_KEY_PATH="$2"

main() {
	install_dependencies
	setup_node_repo
	apt update && apt install -y nodejs
	npm install --global "yarn@$YARN_VERSION"
	install_aws_cli
}

install_dependencies() {

	# gpg: required to install NodeJS
	# lsb-release: required to install NodeJS
	# ca-certificates: required to install NodeJS
	# git: used by pipeline scripts
	# gnupg: required by gcloud cli and the script; should be pre-installed
	# pigz: used by pipeline scripts
	# jq: used by pipeline scripts
	# curl: used to install the AWS CLI
	# unzip: used to install the AWS CLI

	apt update &&
		apt upgrade -y &&
		apt install -y \
			unzip \
			curl \
			gpg \
			lsb-release \
			ca-certificates \
			git \
			gnupg \
			pigz \
			jq
}

setup_node_repo() {

	# Install NodeSource GPG key. Install NodeSource apt repo.

	CURRENT_DIR_NODE=$(pwd)
	cd "$STARTING_DIR"
	DISTRO="$(lsb_release -s -c)"
	KEYRING="/usr/share/keyrings/nodesource.gpg"
	gpg --dearmor <"$NODESOURCE_GPG_KEY_PATH" | tee "$KEYRING" >/dev/null
	gpg --no-default-keyring --keyring "$KEYRING" --list-keys
	echo "deb [signed-by=$KEYRING] https://deb.nodesource.com/$NODE_VERSION $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list
	echo "deb-src [signed-by=$KEYRING] https://deb.nodesource.com/$NODE_VERSION $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list
	cd "$CURRENT_DIR_NODE"
}

install_aws_cli() {

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	curl -o awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig
	gpg --import "$AWS_GPG_KEY_PATH"
	if gpg --verify awscliv2.sig awscliv2.zip 2>&1 | grep -q "Good signature"; then
		echo "INFO: There is a good signature on the awscliv2.zip file." 1>&2
	else
		cat <<-EOF 1>&2
			ERROR: The signature on the awscliv2.zip file doesn\'t
			match. Something fishy may be going on, or the AWS GPG
			key may have been rotated.
		EOF
		exit 1
	fi
	unzip awscliv2.zip
	./aws/install
	aws --version
}

main "$@"
