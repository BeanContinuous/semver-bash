#!/usr/bin/env bats

setup_file() {
    load "../test_helper/common-setup"
    _common_setup
    
    export rand=${RANDOM}
    export semver_major_branch=$(_create_git_branch "${rand}" "semver_major")

    semver_types=("major" "minor" "patch" "pre" "build")
    export selected_type=${semver_types[$rand % ${#semver_types[@]}]}

    export pr_number=$(_create_pr "${semver_major_branch}" "E2E Test PR for +semver:${selected_type} - ${rand}")
}

setup() {
    load "../test_helper/common-setup"
    _common_setup
}

teardown_file() {
    load "../test_helper/common-setup"
    _close_pr "${pr_number}"
    _delete_git_branch "${semver_major_branch}"
}

teardown() {
    echo ""
}

@test "GIVEN semver string in PR title" {
    run bash -c "semver get $pr_number"
    assert_success
    assert_output --partial "Semver type: ${selected_type}"
}

@test "GIVEN PR does not contain semver string" {
    _update_pr "${pr_number}" "E2E Test PR - ${rand}" "test body"
    sleep 20 # in order for Github API to completely update PR before run test
    run bash -c "semver get $pr_number"
    assert_failure
    assert_output --partial "This Pull Request does not contain any semantic version string in title or body."
}

@test "GIVEN semver string in PR body" {
    _update_pr "${pr_number}" "E2E Test PR - ${rand}" "Test body for +semver:${selected_type}"
    sleep 20 # in order for Github API to completely update PR before run test
    run bash -c "semver get $pr_number"
    assert_success
    assert_output --partial "Semver type: ${selected_type}"
}