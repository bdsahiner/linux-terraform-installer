#!/bin/bash

get_distribution() {
    lsb_dist=""
    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi
    echo "$lsb_dist"
}

is_wsl() {
    case "$(uname -r)" in
    *microsoft* ) true ;;
    *Microsoft* ) true ;;
    * ) false;;
    esac
}

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

install_lsb_release() {
    if command_exists sudo; then
        sudo apt-get update && sudo apt-get install -y lsb-release
    else
        apt-get update && apt-get install -y lsb-release
    fi
}
if ! command_exists lsb_release; then
    install_lsb_release
fi

get_upstream_distro() {
    if command_exists lsb_release; then
        upstream_distro=$(lsb_release -is 2>/dev/null)
        if [ -n "$upstream_distro" ]; then
            echo "$upstream_distro"
        else
            echo "$lsb_dist"
        fi
    else
        echo "$lsb_dist"
    fi
}

lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

if is_wsl; then
    echo "Operating System: Windows Subsystem for Linux (WSL)"
else
    dist_version=""
    case "$lsb_dist" in
        ubuntu|debian|linuxmint)
            if command_exists lsb_release; then
                dist_version="$(lsb_release --codename | cut -f2)"
            fi
            if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
                dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
            fi
            echo "Operating System: $lsb_dist"
            echo "Version: $dist_version"
        ;;
        centos|rhel|fedora|amazon)
            if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
                dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
            fi
            echo "Operating System: $lsb_dist"
            echo "Version: $dist_version"
        ;;
        *)
            if command_exists lsb_release; then
                dist_version="$(lsb_release --release | cut -f2)"
            fi
            if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
                dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
            fi
            if [ -z "$lsb_dist" ]; then
              echo "Operating System: Unknown Linux"
            else
              echo "Operating System: $lsb_dist"
            fi
            if [ -n "$dist_version" ]; then
              echo "Version: $dist_version"
            fi
        ;;
    esac
fi

echo "Installing Terraform..."

upstream_distro=$(get_upstream_distro)

case "$upstream_distro" in
    Ubuntu|Debian)
        if command_exists sudo; then
            sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt-get update && sudo apt-get install -y terraform
        else
            apt-get update && apt-get install -y gnupg software-properties-common
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/hashicorp.archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
            apt-get update && apt-get install -y terraform
        fi
        ;;
    CentOS|RHEL|Fedora|AmazonLinux)
        if command_exists sudo; then
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            sudo yum -y install terraform
        else
            yum install -y yum-utils
            yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            yum -y install terraform
        fi
        ;;
    *)
        echo "Terraform installation is not supported on this distribution."
        exit 1
        ;;
esac

if command_exists terraform; then
    echo "Terraform has been successfully installed."
else
    echo "Terraform installation failed."
    exit 1
fi
