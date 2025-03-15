# Prerequisites

**Ensure** you have `curl`by: 

 $ `curl --version`

- If the output is `curl 8.5.0 (x86_64-pc-linux-gnu)...` you can skip the next steps.

- If the output is `bash: curl: command not found` It means `curl` is not installed. Follow the instructions below to install it:

    - For Debian / Ubuntu:  $ `sudo apt update && sudo apt install curl`

    - For Fedora / RHEL: $ `sudo dnf install curl`

# Install Terraform

This script will install the latest stable version of Terraform on your system.

 $ `curl -fsSL https://raw.githubusercontent.com/bdsahiner/linux-terraform-installer/main/terraform-installer.sh -o terraform-installer.sh`

 $ `sudo sh ./terraform-installer.sh`

# Post Installation

After installation, verify that Terraform is installed correctly:

 $ `terraform --version`

# Uninstall Terraform

After installation, verify that Terraform was installed successfully:

- For Debian / Ubuntu: $ `sudo apt purge terraform*`

- For Fedora : $ `sudo dnf remove terraform`

# Disclaimer

This project is not affiliated with, endorsed by, or associated with HashiCorp. The script provided in this repository is intended solely for educational purposes. The author disclaims any liability for any direct or indirect damages or issues that may arise from the use of this script or the installation of Terraform.
