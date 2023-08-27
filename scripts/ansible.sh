#!/bin/sh

# -e to exit immediately if a command exits with a non-zero status
# -u to treat unset variables as an error when substituting
set -eu

main() {

    # Ensure we are root.
    if [ "$(id -u)" != 0 ]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Ensure we are running on Debian.
    if [ -f "/etc/os-release" ]; then

        # Load the variables
        . /etc/os-release

        if [ "$ID" != "debian" ]; then
            echo "According to /etc/os-release, this is not a Debian system."
            echo "Currently, only Debian is supported in this script. Aborting."
            exit 1
        fi
    else
        echo "Could not find /etc/os-release."
        exit 1
    fi

    # Require nano to edit the config.
    if ! command -v nano >/dev/null; then
        echo "Could not find nano. Please install it and try again."
        exit 1
    fi

    # Install absolute basic dependencies
    echo "Installing curl, wget, sudo"
    apt install curl wget sudo -y

    # Create sudo group
    if [ ! $(getent group sudo) ]; then
        echo "Creating 'sudo' group"
        groupadd sudo
    else
        echo "Group 'sudo' exists"
    fi

    # Create "ansible" user
    if ! id "ansible" >/dev/null 2>&1; then
        echo "Creating 'ansible' user"
        useradd -m -s /bin/false -G nosudo ansible
    else
        echo "User 'ansible' exists"
    fi

    # Install authorized_keys
    echo "Installing /home/ansible/authorized_keys"
    mkdir -p /home/ansible/.ssh
    wget -o /home/ansible/.ssh/authorized_keys https://infra.joris.me/authorized_keys
    chown -R ansible:ansible /home/ansible/.ssh
    chmod -R 660 /home/ansible/.ssh

    echo "Done!"
}

main
