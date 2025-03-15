#!/bin/sh
set -e

get_distribution() {
    lsb_dist=""
    dist_version=""
    if [ -r /etc/upstream-release/lsb-release ]; then
        lsb_dist="$(. /etc/upstream-release/lsb-release && echo "$DISTRIB_ID")"
        dist_version="$(. /etc/upstream-release/lsb-release && echo "$DISTRIB_CODENAME")"
    elif [ -r /etc/lsb-release ]; then
        lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
        dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    elif [ -r /etc/os-release ]; then
        . /etc/os-release
        lsb_dist="$ID"
        dist_version="$VERSION_CODENAME"
    fi
    echo "$lsb_dist"
}

lsb_dist=$(get_distribution)
lsb_dist=$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')

# Ensure dist_version is set
if [ -z "$dist_version" ]; then
    if command -v lsb_release >/dev/null; then
        dist_version=$(lsb_release -cs)
    elif [ -f /etc/debian_version ]; then
        dist_version=$(cut -d'.' -f1 /etc/debian_version)
    fi
fi

case "$lsb_dist" in
    ubuntu|debian)
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $dist_version main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update
        sudo apt-get install terraform
        ;;
    centos|rhel)
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y install terraform
        ;;
    amzn)
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        sudo yum -y install terraform
        ;;
    fedora)
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        sudo dnf -y install terraform
        ;;
    *)
        echo "Unsupported distribution: $lsb_dist"
        exit 1
        ;;
esac

echo "Terraform installation completed successfully."
