
### Prerequisites
- Docker
- Java 11+
- jq
- curl

### Recommended VSCode plugins
- Bats (Bash Automated Testing System)
- BASH Extension Pack which includes:
  + shell-format
  + Bash Debug
  + Bash IDE

### Getting started
- Clone the repo
```
git clone --recurse-submodules git@github.com:BeanContinuous/semver-bash.git
```

- To run `semver get` in dev environment, simply run
```
GIT_PLATFORM=GitHub make run-dev args="get"
```

- Setup GitHub PAT for E2E tests
Create file `test/.secrets` then put the GitHub PAT as below:
```
export GITHUB_PAT_OWNER=
export GITHUB_PAT_CONTRIBUTOR=
```
Then run these 2 commands to clone GitHub Sandbox Repositories
```
git clone https://oauth2:${GITHUB_PAT_OWNER}@github.com/BeanGithubSandboxUpstream/semver-bash.git test/sandbox/github/upstream

git clone https://oauth2:${GITHUB_PAT_CONTRIBUTOR}@github.com/PeterBeanBotContributor/semver-bash.git test/sandbox/github/contributor
```

- To run all tests
```
make tests
```
- To run only unit tests
```
make unit-tests
```
- To run only E2E tests
```
make e2e-tests
```


### GitHub OpenApi
#### Where to find documentation for the Github OpenApi generated bash files
1. run `make unpack` to generate the OpenApi code.
2. Go to [vendor/github.com/api/README.md](./vendor/github.com/api/README.md).

#### How to test execute_github_api bash function in a standalone shell session

1. `export PROJECT_ROOT=` absolute path to the project folder. On my machine, this was set to something like `${PROJECT_ROOT}`
2. Setup shell environment
```
source ${PROJECT_ROOT}/test/.secrets 
source ${PROJECT_ROOT}/test/.envrc 

source ${PROJECT_ROOT}/pkg/adaptors/github/openapi/client.sh 
source ${PROJECT_ROOT}/pkg/adaptors/github/execute_github_api.sh
```
3. call the function
```
GITHUB_TOKEN=${GITHUB_PAT_CONTRIBUTOR} execute_github_api orgsGet org=BeanCloudServices
```
   - Please note that GITHUB_TOKEN should be set to the right value be it GITHUB_PAT_CONTRIBUTOR or GITHUB_PAT_OWNER according to the actual permission needed by the query.
   - To print out the generated curl query, add --dry-run to the command above.