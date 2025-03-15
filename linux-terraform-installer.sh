#!/bin/sh

get_distribution() {
    lsb_dist=""
    if [ -r /etc/os-release ]; then
        lsb_dist="$(sudo /etc/os-release && echo "$ID")"
    fi
    echo "$lsb_dist"
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

check_forked() {
    if command_exists lsb_release; then
        set +e
        lsb_release -a -u > /dev/null 2>&1
        lsb_release_exit_code=$?
        set -e
        if [ "$lsb_release_exit_code" = "0" ]; then
            lsb_dist=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'id' | cut -d ':' -f 2 | tr -d '[:space:]')
            dist_version=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'codename' | cut -d ':' -f 2 | tr -d '[:space:]')
        else
            if [ -r /etc/debian_version ] && [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "raspbian" ]; then
                if [ "$lsb_dist" = "osmc" ]; then
                    lsb_dist=raspbian
                else
                    lsb_dist=debian
                fi
                dist_version="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
                case "$dist_version" in
                    12)
                        dist_version="bookworm"
                    ;;
                    11)
                        dist_version="bullseye"
                    ;;
                    10)
                        dist_version="buster"
                    ;;
                    9)
                        dist_version="stretch"
                    ;;
                    8)
                        dist_version="jessie"
                    ;;
                esac
            fi
        fi
    fi
}

is_wsl() {
    case "$(uname -r)" in
    *microsoft* ) true ;;
    *Microsoft* ) true ;;
    * ) false;;
    esac
}

is_darwin() {
    case "$(uname -s)" in
    *darwin* ) true ;;
    *Darwin* ) true ;;
    * ) false;;
    esac
}

lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

if is_wsl; then
    exit 1
fi

if [ -r "/etc/upstream-release/lsb-release" ]; then
    . /etc/upstream-release/lsb-release
    lsb_dist="$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')"
    dist_version="$DISTRIB_CODENAME"
else
    case "$lsb_dist" in
        ubuntu)
            if command_exists lsb_release; then
                dist_version="$(lsb_release --codename | cut -f2)"
            fi
            if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
                dist_version="$( /etc/lsb-release && echo "$DISTRIB_CODENAME")"
            fi
        ;;
        debian|raspbian)
            dist_version="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
            case "$dist_version" in
                12)
                    dist_version="bookworm"
                ;;
                11)
                    dist_version="bullseye"
                ;;
                10)
                    dist_version="buster"
                ;;
                9)
                    dist_version="stretch"
                ;;
                8)
                    dist_version="jessie"
                ;;
            esac
        ;;
        centos|rhel)
            if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
                dist_version="$(sudo /etc/os-release && echo "$VERSION_ID")"
            fi
        ;;
        *)
            if command_exists lsb_release; then
                dist_version="$(lsb_release --release | cut -f2)"
            fi
            if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
                dist_version="$(sudo /etc/os-release && echo "$VERSION_ID")"
            fi
        ;;
    esac
fi

check_forked

case "$lsb_dist" in
    ubuntu|debian|raspbian|centos|fedora|rhel|sles)
    ;;
    *)
        if [ -z "$lsb_dist" ] && is_darwin; then
            exit 1
        fi
        exit 1
    ;;
esac

echo "$lsb_dist"
echo "$dist_version"

case "$lsb_dist" in
    ubuntu|debian|raspbian)
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
        gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update
        sudo apt-get install terraform
    ;;
    centos|rhel)
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y install terraform
    ;;
    fedora)
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        sudo dnf -y install terraform
    ;;
esac
