#!/bin/sh
set -e

get_distribution() {
    lsb_dist=""
    if [ -r /etc/upstream-release/lsb-release ]; then
        lsb_dist="$(. /etc/upstream-release/lsb-release && echo "$DISTRIB_ID")"
    elif [ -r /etc/lsb-release ]; then
        lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    elif [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi
    echo "$lsb_dist"
}

get_codename() {
    dist_codename=""
    if [ -r /etc/upstream-release/lsb-release ]; then
        dist_codename="$(. /etc/upstream-release/lsb-release && echo "$DISTRIB_CODENAME")"
    elif [ -r /etc/lsb-release ]; then
        dist_codename="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    else
        dist_codename="$(lsb_release -cs)"
    fi
    echo "$dist_codename"
}

check_forked() {
    if command -v lsb_release > /dev/null; then
        set +e
        lsb_release -a -u > /dev/null 2>&1
        lsb_release_exit_code=$?
        set -e

        if [ "$lsb_release_exit_code" = "0" ]; then
            lsb_dist=$(lsb_release -a -u 2>&1 | grep -E 'id' | cut -d ':' -f 2 | tr -d '[:space:]')
            dist_version=$(lsb_release -a -u 2>&1 | grep -E 'codename' | cut -d ':' -f 2 | tr -d '[:space:]')
        else
            if [ -r /etc/debian_version ] && [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "raspbian" ]; then
                lsb_dist="debian"
                dist_version="$(sed 's/\..*//' /etc/debian_version)"
            fi
        fi
    fi
}

lsb_dist=$(get_distribution)
lsb_dist=$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')
dist_codename=$(get_codename)

dist_version=""
case "$lsb_dist" in
    ubuntu|debian)
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $dist_codename main" | \
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
