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

    # Export our default config.
    CONF=/tmp/bootstrap.env
	rm $CONF
    echo "# Configure the bootstrapping parameters." >>$CONF
    echo "# Lines starting with a hashtag are comments." >>$CONF
    echo "" >> /tmp/bootstrap >>$CONF
    echo "# Host settings" >>$CONF
    echo "HOSTNAME=$(hostname)" >>$CONF
    echo "" >>$CONF
    echo "# Tailscale settings"
    echo "#     Set TS_ENABLED=0 to disable."
    echo "TS_ENABLED=1" >>$CONF
    echo "TS_AUTH_KEY=ts-auth-" >>$CONF
    echo "" >>$CONF
    echo "# To finish, simply save and exit.">>$CONF
    echo "# To exit WITHOUT continuing, uncomment the following line:">>$CONF
    echo "#exit">>$CONF

    # Throw the user into nano to edit the config.
    nano $CONF

    # Source the config.
    . $CONF

    # Update the hostname in /etc/hostname
    OLDHOSTNAME=$(hostname)
    echo "Updating hostname from '$OLDHOSTNAME' to '$HOSTNAME':"
    echo "  - /etc/hostname"
    sed -i "s/$OLDHOSTNAME/$HOSTNAME/g" /etc/hostname

    # Update the hostname in /etc/hosts
    echo "  - /etc/hosts"
    sed -i "s/$OLDHOSTNAME/$HOSTNAME/g" /etc/hosts
    echo -e "Done\n"

    # Install Tailscale if requested.
    if [ "$TS_ENABLED" = "1" ]; then

        # Bootstrap Tailscale, per https://tailscale.com/kb/installation/
        curl -fsSL https://tailscale.com/install.sh | sh

        # Launch Tailscale
        tailscale up --auth-key $TS_AUTH_KEY
    
    else
        echo -e "TS_ENABLED has non-1 value, skipping Tailscale setup\n"
    fi

    # Install absolute basic dependencies
    echo "Installing curl, sudo"
    apt install curl sudo -y

    # Create sudo group
    if [ ! $(getent group sudo) ]; then
        groupadd sudo
    else
        echo "Group 'sudo' exists"
    fi

    # Create "joris" user
    if ! id "joris" >/dev/null 2>&1; then
        useradd -m -s /bin/bash joris
    else
        echo "User 'joris' exists"
    fi

    # Create "ansible" user
    if ! id "ansible" >/dev/null 2>&1; then
        useradd -m -s /bin/false -G nosudo ansible
    else
        echo "User 'ansible' exists"
    fi

}

main
