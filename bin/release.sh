#!/usr/bin/env bash
release() {
    TASK_NAME=$1
    if [ -z "$TASK_NAME" ]; then
        echo "Please specify the task name"
        exit 0
    fi

    RELEASE_VERSION=$2

    # Specify the YAML file path
    app_file="specs/bashly/app.yml"
    key_version="version"

    # Read the section/block from the YAML file TODO need update ci pipeline to include yq lib
    # TODO we may need to install yq before running this script
    current_version=$(yq eval '.version' "$app_file")

    # Regular expression pattern for semver
    semver_pattern='^v[0-9]+\.[0-9]+\.[0-9]+(\-[0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*)?(\+[0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*)?$'

    # function getting sem version
    get_sem_version() {
        # shellcheck disable=SC2001
        sem_ver=$1
        echo "$sem_ver" | sed -e 's/^v//' -e 's/-.*$//' -e 's/+.*$//'
    }

    get_pre_release_version() {
        pre_release_version=$1
        echo "$pre_release_version" | sed -e 's/^v//' -e 's/^[0-9]*\.[0-9]*\.[0-9]*-//' -e 's/+.*$//'
    }

    REQUEST_SEM_VER=$(get_sem_version $RELEASE_VERSION)
    REQUEST_PRE_RELEASE_VERSION=$(get_pre_release_version $RELEASE_VERSION)

    CURRENT_SEM_VER=$(get_sem_version $current_version)
    CURRENT_PRE_RELEASE_VERSION=$(get_pre_release_version $current_version)

    # function compare sem version
    compare_sem_versions() {
        IFS='.' read -ra ver1_parts <<< "$1"
        IFS='.' read -ra ver2_parts <<< "$2"

        for i in "${!ver1_parts[@]}"; do
            if [[ ${ver1_parts[i]} > ${ver2_parts[i]} ]]; then
    #             echo "$1 is greater than $2"
                echo 1
                return
            elif [[ ${ver1_parts[i]} < ${ver2_parts[i]} ]]; then
    #             echo "$1 is less than $2"
                echo 0
                return
            fi
        done

        # If we haven't returned yet, versions are equal
    #     echo "$1 is equal to $2"
        echo 1
    }

    # compare pre release version in alphabetical order
    compare_pre_release() {
        IFS='.' read -ra ver1_parts <<< "$1"
        IFS='.' read -ra ver2_parts <<< "$2"

        # Compare each part
        for i in "${!ver1_parts[@]}"; do
            # If one of the versions doesn't have this part, the other is greater
            if [[ -z "${ver1_parts[i]}" ]]; then
    #             echo "$1 is less than $2"
                echo 1
                return
            elif [[ -z "${ver2_parts[i]}" ]]; then
    #             echo "$1 is greater than $2"
                echo 0
                return
            fi

            # Compare numeric vs. non-numeric
            if [[ "${ver1_parts[i]}" =~ ^[0-9]+$ && ! "${ver2_parts[i]}" =~ ^[0-9]+$ ]]; then
    #             echo "$1 is less than $2"
                echo 1
                return
            elif [[ ! "${ver1_parts[i]}" =~ ^[0-9]+$ && "${ver2_parts[i]}" =~ ^[0-9]+$ ]]; then
    #             echo "$1 is greater than $2"
                echo 0
                return
            elif [[ "${ver1_parts[i]}" =~ ^[0-9]+$ && "${ver2_parts[i]}" =~ ^[0-9]+$ ]]; then
                # Both are numeric, so compare as numbers
                if (( ${ver1_parts[i]} > ${ver2_parts[i]} )); then
    #                 echo "$1 is greater than $2"
                    echo 0
                    return
                elif (( ${ver1_parts[i]} < ${ver2_parts[i]} )); then
    #                 echo "$1 is less than $2"
                    echo 1
                    return
                fi
            else
                # Both are non-numeric, so compare as strings
                if [[ "${ver1_parts[i]}" > "${ver2_parts[i]}" ]]; then
    #                 echo "$1 is greater than $2"
                    echo 1
                    return
                elif [[ "${ver1_parts[i]}" < "${ver2_parts[i]}" ]]; then
    #                 echo "$1 is less than $2"
                    echo 0
                    return
                fi
            fi
        done

        # If we haven't returned yet, versions are equal
    #     echo "$1 is equal to $2"
        echo 1
    }

    pre_release_result=$(compare_pre_release $CURRENT_PRE_RELEASE_VERSION $REQUEST_PRE_RELEASE_VERSION)
    compare_sem_versions_result=$(compare_sem_versions $CURRENT_SEM_VER $REQUEST_SEM_VER)

    master_branch="master"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    latest_tag_id=$(git rev-parse -q --verify "refs/tags/latest")
    nightly_tag_id=$(git rev-parse -q --verify "refs/tags/nightly")
    nightly_tag_name="nightly"
    latest_tag_name="latest"

    if [ -z "$RELEASE_VERSION" ] && [ "$TASK_NAME" = "release" ] && [ "$current_branch" != $master_branch ]
    then
        echo "Please specify the version which you want to release for the current branch $current_branch"
        exit 0
    fi
  if [ "$current_branch" = "$master_branch" ]; then
      echo "Current branch is $master_branch"
      # Check if the input string matches the semver pattern
      if [[ $current_version =~ $semver_pattern ]]; then
          echo "Releasing supported version"
          if [ -z "$latest_tag_id" ];
              then
                echo "The current version is already latest"
                echo "Current version is $app_version. Updating 'latest' tag..."

                git tag $latest_tag_name
                git push origin $latest_tag_name
                echo "Tag 'latest' has been updated to the current commit and pushed to remote origin."
                echo pass ac 5
                exit 0
          else
              echo "The current version is already latest"
              echo "Current version is $app_version. Updating 'latest' tag..."
              git tag -d $latest_tag_name
              git push --delete origin $latest_tag_name
              echo "Deleted $latest_tag_name"

              git tag $latest_tag_name
              git push origin $latest_tag_name
              echo "Tag 'latest' has been updated to the current commit and pushed to remote origin."
              echo pass ac 6
              exit 0
          fi
      else
          echo "Releasing nightly version"
                # AC 3
            if [ -z "$nightly_tag_id" ];
                then
                    echo "The current version is already latest"
                    # Tag the current commit as 'nightly'
                    git tag $nightly_tag_name
                    # Push the newly created 'nightly' tag to remote origin

                    git push origin $nightly_tag_name
                    echo "Tag 'nightly' has been created and pushed to remote origin."
                    exit 0
            elif [ "$latest_tag_name" = "$nightly_tag_name" ]; # AC4
                then
                    echo "Releasing the current version"
                    git tag -d $nightly_tag_name
                    git push --delete origin $nightly_tag_name
                    echo "Deleted current nightly tag"

                    git tag nightly
                    git push origin nightly
                    echo "Tag 'nightly' has been created and pushed to remote origin."
                    echo "Pass ac 4"
                    exit 0
            else
                    echo "Do nothing"
            fi
      fi
  else
      # AC 1
      if [[ $pre_release_result = 0  || $compare_sem_versions_result -eq 0 ]];
          then
                # Use yq to update the YAML file
                yq eval ".$key_version = \"$RELEASE_VERSION\"" -i "$app_file"
                make build
                # git checkout specs/bashly/app.yml # for local testing
                git add specs/bashly/app.yml
                git commit -m "Update version to $RELEASE_VERSION"
                git push
                echo "Pushed code to remote branch."
                exit 0
      elif [ "$current_version" = "$RELEASE_VERSION" ];
          then
              echo "The release version is latest."
              exit 0
      fi
  fi
}