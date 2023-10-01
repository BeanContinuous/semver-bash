#!/usr/bin/env bash

# Print the section

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"
cd "${PROJECT_ROOT}"


# shellcheck source=bin/config.sh
source bin/config.sh
source bin/release.sh

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
    release)
       release $1 $2
    ;;
    *)
        exit 0
    ;;
esac
