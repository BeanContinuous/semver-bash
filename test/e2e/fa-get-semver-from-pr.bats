setup_file() {
    load '../test_helper/common-setup'
    _common_setup
    
    export rand=${RANDOM}
    export semver_major_branch=$(_create_git_branch "${rand}" "semver_major")

    export pr_number=$(_create_pr "${semver_major_branch}" "E2E Test PR - ${rand}" | jq -r '.number')
}

teardown_file() {
    echo ""
    _close_pr "${pr_number}"
    _delete_git_branch "${semver_major_branch}"
}

setup() {
    echo ""
}

teardown() {
    echo ""
}

@test "test creating PR" {
    echo ""

    # run semver get
}
