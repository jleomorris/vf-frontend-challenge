reconfigure:
	terragrunt init -reconfigure
remove-local-state:
	find . -type d -name ".terraform" -prune -exec rm -rf {} \;
clear-terragrunt-cache:
	find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
