#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

flex_script='flex.sh'
auto_update="${auto_update:-1}"
service_config_path='./service_config.yml'
install_folder_name='.flex'
install_path="${install_path:=./${install_folder_name}}"
user_scripts_install_path="${install_path}/scripts/user"
flex_binary_path="${install_path}/flex"
flex_version_command="${flex_binary_path} -version"

running_script_path="./${flex_script}"
latest_script_path="${user_scripts_install_path}/${flex_script}"

if [[ -f "${latest_script_path}" ]]; then
    running_script_contents=$(cat "${flex_script}")
    latest_script_contents=$(cat "${latest_script_path}")

    if [[ "${running_script_contents}" != "${latest_script_contents}" ]]; then
        echo "There's a new version of this script, switching!"
        install -cv "${latest_script_path}" .
        ${running_script_path} "$@"
        exit 0
    fi
fi

install_flex() {
    version_to_install="${1:-latest}"
    skip_download=${skip_download:=0}
    download_folder_path="${download_folder_path:=./dist}"

    echo "Installing flex version $version_to_install!"

    # Generate the platform specific file name to download.
    os=$(uname | tr '[:upper:]' '[:lower:]')
    file_name="flex_${os}_amd64.tar.gz"
    base_url='https://github.com/fp-mt-test-org/flex/releases'
    if [[ "${version_to_install}" == "latest" ]]; then
        url="${base_url}/latest/download/${file_name}"
    else
        url="${base_url}/download/v${version_to_install}/${file_name}"
    fi

    mkdir -p "${install_path}"
    mkdir -p "${download_folder_path}"

    download_file_path="${download_folder_path}/${file_name}"

    if [ "${skip_download}" -ne "1" ]; then
        echo "Downloading ${url} to ${download_file_path}"
        curl -L "${url}" --output "${download_file_path}"
    fi

    echo "Extracting ${download_file_path} to ${install_path}"
    tar -xvf "${download_file_path}" -C "${install_path}"

    if [[ "${version_to_install}" != "latest" ]] && [[ -f "${service_config_path}" ]]; then
        echo "Updating version in ${service_config_path} to ${version_to_install}"
        service_config_content=$(cat ${service_config_path})
        updated_service_config_content="${service_config_content/0.3.0/${version_to_install}}"
        echo "${updated_service_config_content}" > "${service_config_path}"
        echo "${service_config_path} updated!"
    fi

    git_ignore_file='.gitignore'

    if ! grep -qs "${install_folder_name}" "${git_ignore_file}"; then
        echo "Updating ${git_ignore_file} to ignore the ${install_path} install_path..."
        echo "${install_folder_name}" >> "${git_ignore_file}"
    fi

    echo "Configuring the local host..."
    "${user_scripts_install_path}/configure-localhost.sh"

    if [ "${auto_clean:=1}" == "1" ]; then
        echo "Cleaning up ${download_file_path}"
        rm "${download_file_path}"
    fi

    echo "Installation complete!"
    echo ""
}

get_configured_version() {
    service_config_content=$(cat ${service_config_path})

    if [[ "${service_config_content}" =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
        flex_version="${BASH_REMATCH[0]}"
        echo "${flex_version}"
    else
        echo "ERROR: Version not found!"
        exit 1
    fi
}

#echo "Checking if Flex needs to be installed, updated or initialized..."

if ! [[ -d "${install_path}" ]]; then
    #echo "${install_path} not found locally, Flex needs to be installed."
    should_install_flex="1"
fi

if [[ -f "${service_config_path}" ]]; then
    #echo "${service_config_path} exists!"
    #echo "Flex has been previously initialized for this repo, reading flex version..."
    version_to_install=$(get_configured_version)
    #echo "Configured version is ${version_to_install}"
else
    if ! [[ -f "./${flex_script}" ]]; then
        echo "${flex_script} not found in current dir ($(pwd))."

        if [[ "${1:-}" == "" ]]; then
            echo "No parameters specified to this script, saving script locally to install it..."
            cp "${BASH_SOURCE[0]}" .
            exit 0
        fi
    fi
fi

if [[ "${should_install_flex:=0}" == "1" ]]; then
    install_flex "${version_to_install:=latest}"
fi

#echo "Getting current flex version with: ${flex_version_command}"

initial_flex_version=$(${flex_version_command})

#echo "initial_flex_version: ${initial_flex_version}"

# Check the service_config, if it exists (i.e. is not first run of flex)
if [[ "${auto_update}" == "1" ]] && [[ -f "${service_config_path}" ]]; then
    service_config=$(cat ${service_config_path})

    if [[ "${service_config}" =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
        configured_flex_version="${BASH_REMATCH[0]}"
        #echo "service_config: flex: version: ${configured_flex_version}"

        # Regex for matching snapshot versions such as v0.8.3-SNAPSHOT-27afad4
        configured_flex_version_regex=".*${configured_flex_version}.*"

        if ! [[ "${initial_flex_version}" =~ ${configured_flex_version_regex} ]]; then
            echo "Current version ${initial_flex_version} is different than configured ${configured_flex_version}, updating..."
            install_flex "${configured_flex_version}"
            echo "Current version is now:"
            ${flex_version_command}
            echo "Update complete."
        fi
    fi
fi

"${flex_binary_path}" "${@:--version}"
