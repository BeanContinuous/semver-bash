#!/usr/bin/env bats

setup_file() {
    load "../test_helper/common-setup"
    _common_setup
    
    export rand=${RANDOM}
    export semver_major_branch=$(_create_git_branch "${rand}" "semver_major")

    semver_types=("major" "minor" "patch" "pre" "build")
    export selected_type=${semver_types[$rand % ${#semver_types[@]}]}

    export pr_number=$(_create_pr "${semver_major_branch}" "E2E Test PR for +semver:${selected_type} - ${rand}")
    echo "setup_file funtion  pr_number${pr_number}" >> /home/dungquack/semver-bash/debug.log
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

    #_update_pr "${pr_number}" "E2E Test PR for +semver:${selected_type} - ${rand}" "test body"
    echo "${pr_number} ___ ${semver_major_branch} ------- E2E Test PR for +semver:${selected_type} - ${rand}" 
    run bash -c "semver get $pr_number" 
    echo -e "\nGIVEN semver string in PR title  pr_number${pr_number}" >> /home/dungquack/semver-bash/debug.log
    assert_success
    assert_output --partial "Semver type: ${selected_type}"   
    
}



@test "GIVEN PR does not contain semver string" {

    echo "${pr_number} ___ ${semver_major_branch} ------- E2E Test PR for +semver:${selected_type} - ${rand}" 
    _update_pr "${pr_number}" "E2E Test PR - ${rand}" "test body"
    sleep 20 # in order for Github API to completely update PR before run test
    run bash -c "semver get $pr_number" 
    echo -e "\nGIVEN PR does not contain semver string  pr_number${pr_number}" >> /home/dungquack/semver-bash/debug.log
    assert_failure
    assert_output --partial "This Pull Request does not contain any semantic version string in title or body." 
    
}

@test "GIVEN semver string in PR body" {

    echo "${pr_number} ___ ${semver_major_branch} ------- E2E Test PR for +semver:${selected_type} - ${rand}" 
    _update_pr "${pr_number}" "E2E Test PR - ${rand}" "Test body for +semver:${selected_type}"
    sleep 20 # in order for Github API to completely update PR before run test
    run bash -c "semver get $pr_number" 
    echo -e "\nGIVEN semver string in PR body  pr_number${pr_number}" >> /home/dungquack/semver-bash/debug.log
    assert_success
    assert_output --partial "Semver type: ${selected_type}" 
    
}

