## initialize hook
##
## Any code here will be placed inside the `initialize()` function and called
## before running anything else.
##
## You can safely delete this file if you do not need it.

# execute_github_api orgsGet org=BeanCloudServices;

detect_git_platform

project_port_1() { project_adaptor_1; }

no_adaptor_available() {
  echo '{"message": "No adaptor available"}'
  exit 1
}

case "${GIT_PLATFORM}" in
  "GitHub")
    # get_pr_git_adaptor=no_adaptor_available
    get_pr_git_adaptor=get_pr_github_adaptor
    ;;
  *)
    get_pr_git_adaptor=no_adaptor_available
    ;;
esac

get_pr_git_port() { ${get_pr_git_adaptor} "$@"; }
