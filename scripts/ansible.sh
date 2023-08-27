#!/bin/sh

# -e to exit immediately if a command exits with a non-zero status
# -u to treat unset variables as an error when substituting
set -eu

print_header() {
    echo "\n################################"
    echo "# $1"
    echo "################################\n"
}

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

    ################################
    # Dependencies
    ################################

    # Install absolute basic dependencies
    print_header "Dependencies"
    echo "Installing curl, sudo"
    apt install curl sudo -y

    ################################
    # User management
    ################################
    print_header "User management"

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
        useradd -m -s /bin/bash -G sudo ansible
    else
        echo "User 'ansible' exists"
    fi

    ################################
    # sshd cofiguration
    ################################
    print_header "sshd configuration"

    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^#AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^#AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    ################################
    # SSH authorized_keys
    ################################
    print_header "SSH authorized_keys"

    # Install authorized_keys
    echo "Installing /home/ansible/authorized_keys"
    mkdir -p /home/ansible/.ssh
    curl -sfo /home/ansible/.ssh/authorized_keys https://infra.joris.me/authorized_keys
    chown -R ansible:ansible /home/ansible/.ssh
    chmod 700 /home/ansible/.ssh
    chmod 644 /home/ansible/.ssh/authorized_keys

    ################################
    # Tailscale
    ################################
    print_header "Tailscale"

    # Obtain Tailscale auth key
    read -p "Enter Tailscale auth key (press enter to skip): " TS_AUTH_KEY </dev/tty

    if [ ! -z "$TS_AUTH_KEY" ]; then
        # Bootstrap Tailscale, per https://tailscale.com/kb/installation/
        echo "Installing Tailscale"
        curl -fsSL https://tailscale.com/install.sh | sh

        # Enable Tailscale with the given auth key
        tailscale up --auth-key $TS_AUTH_KEY
    fi

    reboot
}

main
