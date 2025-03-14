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

is_darwin() {
    case "$(uname -s)" in
    *darwin* ) true ;;
    *Darwin* ) true ;;
    * ) false;;
    esac
}

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

if is_wsl; then
    echo "Operating System: Windows Subsystem for Linux (WSL)"
elif is_darwin; then
    echo "Operating System: macOS"
else
    dist_version=""
    case "$lsb_dist" in
        ubuntu|debian)
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

# Terraform Installation
echo "Installing Terraform..."

case "$lsb_dist" in
    ubuntu|debian)
        if command_exists sudo; then
            sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt-get update && sudo apt-get install -y terraform
        else
            apt-get update && apt-get install -y gnupg software-properties-common
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
            apt-get update && apt-get install -y terraform
        fi
    ;;
    centos|amazon)
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
    fedora)
        if command_exists sudo; then
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            sudo dnf -y install terraform
        else
            dnf install -y dnf-plugins-core
            dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            dnf -y install terraform
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
