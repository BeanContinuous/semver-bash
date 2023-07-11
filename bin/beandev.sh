#!/usr/bin/env bash

# check current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
latest_tag=$(git rev-parse -q --verify "refs/tags/latest")
nightly_tag=$(git rev-parse -q --verify "refs/tags/nightly")
TASK_NAME=$1
if [ -z "$TASK_NAME" ]; then
    echo "Please specify the task name"
    exit 1
fi
RELEASE_VERSION=$2

if [ -z "$RELEASE_VERSION" ] && [ "$TASK_NAME" = "release" ] && [ "$current_branch" != "master" ]
then
    echo "Please specify the version which you want to release"
    exit 1
fi
# Specify the YAML file path
app_file="specs/bashly/app.yml"
key_version="version"

# Read the section/block from the YAML file TODO need update ci pipeline to include yq lib
version=$(yq eval '.version' "$app_file")

# Print the section
echo "$version"

if [ "$current_branch" = "master" ]; then
    echo "Current branch is master"
    # AC 3
    if [ "$version" = "v0.1.0-alpha" ] && [-z $nightly_tag]
        then
            echo "Start nightly build"
            # Tag the current commit as 'nightly'
            git tag nightly
            # Push the newly created 'nightly' tag to remote origin

            git push origin nightly
            echo "Tag 'nightly' has been created and pushed to remote origin."
    elif [ "$version" = "v0.1.0-beta+500"] && [ -z $latest_tag ] # AC4
        then
            echo "AC 5: Releasing the current version"
    elif [ "$version" = "v0.1.0"] && [ -z $latest_tag]# AC5
            # TODO: how to check if there is no latest tag?
            then
                echo "AC 5: the current version is already latest"
                # Display the current version and delete/create 'latest' tag
                echo "Current version is $app_version. Updating 'latest' tag..."
                git tag -d latest
                git tag latest
                # Push the newly created 'latest' tag to remote origin
                git push origin latest
                echo "Tag 'latest' has been updated to the current commit and pushed to remote origin."
    elif [ "$version" = "v0.1.0"] && [ latest_tag >/dev/null ]# AC6
            then
                echo "AC 6: the current version is already latest"
                # Display the current version and delete/create 'latest' tag
                echo "Current version is $app_version. Updating 'latest' tag..."
                git tag -d latest
                git tag latest
                # Push the newly created 'latest' tag to remote origin
                git push origin latest
                echo "Tag 'latest' has been updated to the current commit and pushed to remote origin."
    fi
else
    # TODO the version in the requirement is v0.1.0-alpha+100
    # AC 1
    if [ "$version" = "v0.1.0-alpha" ]
        then
            # Use yq to update the YAML file
            yq eval ".$key_version = \"$RELEASE_VERSION\"" -i "$app_file"
            make build
            # git checkout specs/bashly/app.yml # for local testing
            git add specs/bashly/app.yml
            git commit -m "Update version to $version"
            git push
            echo "Pushed code to remote branch."
            exit 0
    # AC 2
    elif [ "$version" = "$RELEASE_VERSION" ]
        then
            echo "The release version is latest."
            exit 0
    else
        echo $version
        echo "The version is not v0.1.0-beta+500 or " $RELEASE_VERSION
        exit 0
    fi
fi

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"
cd "${PROJECT_ROOT}"


# shellcheck source=bin/config.sh
source bin/config.sh

case $1 in
    init)
        if [[ -f "specs/bashly/app.yml" ]]; then echo "Bashly already initiated"; exit 0; fi
        bashly-docker init
        mkdir -p "specs/bashly/"
        if [[ -f "cmd/bashly.yml" ]]; then mv cmd/bashly.yml specs/bashly/app.yml; fi

        git submodule add https://github.com/bats-core/bats-core.git test/bats
        git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
        git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert


    ;;

    check-software)
        # java, docker
        if ! command -v java &> /dev/null
        then
            echo "java could not be found"
            exit 1
        fi

    ;;

    bashly)
        bashly-docker "${@:2}"
    ;;
    
    download-dependencies)        
        if [[ ! -d "${VENDOR_OPENAPI_TOOL_GEN}/openapi-generator-${OPENAPI_GEN_VERSION}" ]]; then
            echo "Downloading OpenApi Generator v${OPENAPI_GEN_VERSION}"
            mkdir -p ${VENDOR_OPENAPI_TOOL_GEN}

            curl -sL https://github.com/OpenAPITools/openapi-generator/archive/refs/tags/v${OPENAPI_GEN_VERSION}.tar.gz | tar xz -C ${VENDOR_OPENAPI_TOOL_GEN}

            echo "Setting up openapi-generator-cli.sh"
            chmod u+x "${OPENAPI_GEN_CLI}"
            eval "${OPENAPI_GEN_CLI}" help > /dev/null 2>&1
        fi
    ;;
    
    generate-openapi-client)
        mkdir -p "${VENDOR_GITHUB_API}"
        package_name="${2}"
        specs_url="${3}"
        if [[ ! -f "${VENDOR_GITHUB_API}/client.sh" ]]; then
            printf "\nDownloading ${package_name} OpenApi specs\n"

            specs_downloader="${SPECS_OPENAPI_VENDOR}/${package_name}.sh"
            if [[ -f "${specs_downloader}" ]]; then
                specs_file=$("${SPECS_OPENAPI_VENDOR}/${package_name}.sh")
            else
                specs_file="${SPECS_OPENAPI_VENDOR}/${package_name}.specs"
                if [[ -f "${specs_file}" ]]; then
                    exit 0
                fi
                curl -s "${specs_url}" --output "${specs_file}"
            fi
            echo "Generating OpenApi Client for ${package_name}"
            ${OPENAPI_GEN_CLI}  generate -g bash -i "${SPECS_OPENAPI_VENDOR}/github_api.json" -t "${PROJECT_ROOT}/openapi-templates" --package-name github_api -o "${VENDOR_GITHUB_API}" --skip-validate-spec > /dev/null 2>&1

            chmod u+x "${VENDOR_GITHUB_API}"/*.sh

            echo "Copying generated client to project"
            cp -p "${VENDOR_GITHUB_API}/client.sh" "${PROJECT_ROOT}/pkg/adaptors/github/openapi"

        fi
    ;;

    dev)
        ENV=development bashly-docker generate
    ;;

    build)
        ENV=production bashly-docker generate
    ;;

    unit-test)
        if [[ -z "$2" ]]; then
            echo "HINT: We have two ways to do this"
            echo ""
            echo "   make unit-test TEST_PATH=project/feature"
            echo ""
            echo "   ./bin/beandev.sh unit-test project/feature"
        else 
            echo Running unit tests for "${@:2}"
            full_test_path=${PROJECT_ROOT}/pkg/${2}.bats
            PROJECT_ROOT=${PROJECT_ROOT} ./test/bats/bin/bats ${full_test_path}
            
        fi        
    ;;

    unit-tests)
        test_paths=($(find .  -not -path "*/test_helper/*"  -not -path "*/bats/*" -not -path "*/test/*" -type f -name "*.bats"))
        for test_path in "${test_paths[@]}"
        do
            # echo test_path "${test_path}"
            PROJECT_ROOT=${PROJECT_ROOT} ./test/bats/bin/bats "${test_path}"
        done

        # pkg_test_paths=($(find pkg  -not -path "*/test_helper/*"  -not -path "*/bats/*" -type f -name "*.bats"))  
        # for test_path in "${pkg_test_paths[@]}"
        # do
        #     # echo test_path "${test_path}"
        #     PROJECT_ROOT=${PROJECT_ROOT} ./test/bats/bin/bats "${test_path}"
        # done

        # cmd_test_paths=($(find cmd  -not -path "*/test_helper/*"  -not -path "*/bats/*" -type f -name "*.bats"))
  
        # for test_path in "${cmd_test_paths[@]}"
        # do
        #     # echo test_path "${test_path}"
        #     PROJECT_ROOT=${PROJECT_ROOT} ./test/bats/bin/bats "${test_path}"
        # done

    ;;

    *)
        exit 0
    ;;
esac
