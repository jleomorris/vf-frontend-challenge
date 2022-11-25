#!/usr/bin/env bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
local_branch_name="$(git rev-parse --abbrev-ref HEAD)"

valid_branch_regex='^((chore|fix|feature|hotfix|refactor|release|story)\/[a-zA-Z0-9\-]+)$'

message="There is something wrong with your branch name.\n
Branch names in this project must adhere to this contract:\n
${RED}$valid_branch_regex.${NC}\n 
Please rename your branch to a valid name and try again.\n 
For more information on correct branch naming please read:\n
${GREEN}https://visfo.atlassian.net/wiki/spaces/EN/pages/2807758849/Git+Etiquette${NC}"

if [[ ! $local_branch_name =~ $valid_branch_regex ]]; then
    echo -e "$message"
    exit 1
fi

exit 0
