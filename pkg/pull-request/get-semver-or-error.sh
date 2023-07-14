#!/usr/bin/env bash

#######################################
# Check if the PR has semver or not
# Globals:
#   None
# Arguments:
#   pr
#######################################

function pr.get_semver_or_error() {
    declare -A pr_details
    pr_details["title"]=$(echo "$1" | jq -r ".title")
    pr_details["body"]=$(echo "$1" | jq -r ".body")

    pr.has_semver pr_details > /dev/null
    if [[ -v pr_details["semver_type"] ]]; then
        echo "Semver type: ${pr_details["semver_type"]}"
        exit 0
    fi
    echo "This Pull Request does not contain any semantic version string in title or body."
    exit 1
}
