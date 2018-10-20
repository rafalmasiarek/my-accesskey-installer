#!/bin/bash

WHOAMI=`whoami`

display_help() {
    echo ""
    echo "========================== MASIAREK.GURU =========================="
    echo ""
    echo "You need to be root to run this script."
    echo "Usage: $0 [option...] {add|remove}"
    echo ""
    echo "   add {--sudo}    Add user with my public key to access to server"
    echo "                   (with sudo privilages or not)"
    echo "   remove          Remove my public key from server"
    echo "   help,--help,-h  Print this help message"
    echo ""
}

if [ $# -gt 0 ]; then
   case "$1" in
       --help|help|-h)
           display_help
       ;;
    esac
fi


if [ "$WHOAMI"=="root" ]
then

    KEY=''
    SUDO=false
    FLAG=$1
    if [ "$FLAG" == "add" ]; then
        if [ `getent passwd | grep -c '^rmasiare:'` != "1" ]; then

            if [ $# > 1 ]; then
                 if [ "$2" == "--sudo" ]; then
                     SUDO=true
                 fi
            fi

            echo "Creating user..."
            useradd -m rmasiare
            mkdir -p /home/rmasiare/.ssh
            touch /home/rmasiare/.ssh/authorized_keys
            echo "Downloading SSH Key..."
            wget https://www.dropbox.com/s/anjgi2865y0g8vi/rsa-key?dl=1 -O /tmp/rsa-key >/dev/null 2>&1
            echo "Downloading SHA Checksum..."
            wget https://www.dropbox.com/s/57yay4gz4n6xof5/rsa-key-checksum?dl=1 -O /tmp/rsa-key-checksum >/dev/null 2>&1

            CHECKSUM=`cat /tmp/rsa-key-checksum | awk '{ print $1 }'`
            KEYSUM=`sha256sum /tmp/rsa-key | awk '{ print $1 }'`

            if [ "${CHECKSUM}" == "${KEYSUM}" ]; then
                KEY=`cat /tmp/rsa-key`
                #echo "from=\"89.238.158.73\" $KEY MASIAREKGURU-KEY" >> /home/rmasiare/.ssh/authorized_keys
                echo "$KEY" >> /home/rmasiare/.ssh/authorized_keys
                rm -f /tmp/rsa-key
                rm -f /tmp/rsa-key-checksum
                echo "Key installed"
            else
                echo "Could not install Key. Checksum failed." 
            fi

            chmod 700 /home/rmasiare/.ssh
            chown rmasiare:rmasiare /home/rmasiare/.ssh
            chmod 600 /home/rmasiare/.ssh/authorized_keys
            chown rmasiare:rmasiare /home/rmasiare/.ssh/authorized_keys

            if [ `grep -c "AllowUsers" /etc/ssh/sshd_config` -gt "0" ]; then
                echo -e "\nAllowUsers rmasiare" >> /etc/ssh/sshd_config
            fi

            # Add me to sudoers
            if [ "$SUDO" == "true" ]; then
                echo "Adding user to sudo group..."
                echo "#Add rmasiare to sudoers. Generated on `date`" > /etc/sudoers.d/90-rmasiare-sysadmin-user
                echo "rmasiare ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-rmasiare-sysadmin-user
            fi

            echo -e "\nMatch User rmasiare\n\tPubkeyAuthentication yes\n\tPasswordAuthentication no" >> /etc/ssh/sshd_config

            # CentOS 7
            systemctl restart sshd >/dev/null 2>&1
	       # Debian
            service sshd restart >/dev/null 2>&1
	       # CentOS 6>
            service ssh restart >/dev/null 2>&1
        else
            echo "User rmasiare exist on your system, if you want to delete him, use this script with remove parameter."
        fi

    elif [ "$FLAG" == "remove" ]; then
         userdel -rf rmasiare
	 rm -rf /home/rmasiare
         rm -rf /etc/sudoers.d/90-rmasiare-sysadmin-user >/dev/null 2>&1
    else
         display_help
    fi
else
    echo "You need to be root to run this script."
fi
