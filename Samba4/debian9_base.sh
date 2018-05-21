#!/bin/bash
##################################################
# Name: debian9_base.sh
# Description: Base preparation for Linux Debian Jessie 9.40
# Script Maintainer: Rafael and Douglas
#
# Versão: 1.0
# Last Updated: May 21th 2018
##################################################
#

##################################################
#Include source file with text functions
#
echo "Dependency check"
echo ""
while true; do
	if [ ! -f textfuncs.fnc ]; then
		echo "Downloading config file"
		echo ""
		if ! wget -q -t2 goo.gl/klNlVy -O textfuncs.fnc; then
			echo "Could not download text functions"
			exit 0
		fi
		# echo "checking file integrity"
	fi
  break
done
sleep 3
echo "Including text functions"
source textfuncs.fnc
##################################################


function fixRclocal() {
##################################################
# Fix rc.local on debian 9 systems
#
# Creating rc-local.service

if [ ! -f /etc/rc.local ]; then

cat <<EOF >>/etc/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

#Creating rc.local
cat <<EOF >>/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
	# Changing permissions
	chmod +x /etc/rc.local
	# Enabling script on boot
	systemctl enable rc-local
	# Start script
	systemctl start rc-local.service
fi
}

################################################
# Network functions
cidr2mask() { # function to convert the netmask
  local i mask=""
  local full_octets=$(($1/8))
  local partial_octet=$(($1%8))

  for ((i=0;i<4;i+=1)); do
    if [ $i -lt $full_octets ]; then
      mask+=255
    elif [ $i -eq $full_octets ]; then
      mask+=$((256 - 2**(8-$partial_octet)))
    else
      mask+=0
    fi  
    test $i -lt 3 && mask+=.
  done

  echo $mask
}

# Function calculates number of bit in a netmask
#
mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}

################################################

function changeRootPasswd() {
  # Password 
  # $1$AFGBC6.8$voSsSf4Tb914hdSxazccS1
  # $1$4b2NnLOl$yWLDq5X7wZ1Kw7L4dyzhS0
  # To generate a new password use $(echo -n "P4sSw0rD" | openssl passwd -1 -stdin)
  echo -n "Changing root's Password"
  if usermod -p '$1$4b2NnLOl$yWLDq5X7wZ1Kw7L4dyzhS0' root; then
    echo " - successfully updated"
  else
    echo " - update failed"
  fi
}


function SuggestNetworkParameters() { # The idea is to get only the FQDN and understand the rest of the configuration
##################################################
#Suggesting Default Parameters
#
local ipFinal=$1
[ $# -eq 0 ] && { local ipFinal=12; }
# INTERFACE="eth0"
#Verifying if the computer has a static ip address
	if $(cat /etc//network/interfaces | grep -q "inet static"); then
		echo "This system already have a static ip address"
		R_Gat=$(ip r | grep default | awk '{print $3}')
		R_Interface=$(ip r | grep default | awk '{print $5}')
		R_Mask=$(cidr2mask $(ip r | grep src | awk '{print $1}' | cut -d '/' -f2))
		R_IP="$(ip r | grep src | awk '{print $9}')"
		R_Network="$(ip r | grep src | awk '{print $1}' | cut -d '/' -f1)"
		R_Broad="$(echo ${R_Network%.*}).255"
		R_DNS="8.8.8.8"
		R_FQDN="$(cat /etc/hostname)"
		
		echo "
		Your Network parameters in Interface $R_Interface are:
		
		IP Address: $R_IP
		Netmask: $R_Mask
		Gateway: $R_Gat
		Network: $R_Network
		Broadcast: $R_Broad
		DNS: $R_DNS
		Domain: $R_FQDN
		
		"
		read -p "Press [Enter] to continue"
	else
		#Getting the ip address
		R_Gat=$(ip r | grep default | awk '{print $3}')
		R_Interface=$(ip r | grep default | awk '{print $5}')
		R_Mask=$(cidr2mask $(ip r | grep src | awk '{print $1}' | cut -d '/' -f2))
		R_Network="$(ip r | grep src | awk '{print $1}' | cut -d '/' -f1)"
		R_IP="$(echo ${R_Network%.*}).$ipFinal"
		R_Broad="$(echo ${R_Network%.*}).255"
		R_DNS="8.8.8.8"
		#R_FQDN="vpnserver"
		
		Colorize 2 "Please create a name for this Host (without spaces), ex. server.empresa.local: "
		read R_FQDN
		
		if [ $R_FQDN = "" ]; then
			Colorize 1 "We need you to create a name for this host"
			SuggestNetworkParameters
		fi
		
		R_Host=$(echo ${R_FQDN%%.*} | tr '[:upper:]' '[:lower:]')
		R_FQDN=$(echo ${R_FQDN#*.} | tr '[:upper:]' '[:lower:]')
		C_FQDN=$(echo $R_FQDN | tr '[:lower:]' '[:upper:]')
		R_Domain=$(echo ${C_FQDN%.*})
		
		echo "
		Suggested Parameters in Interface $R_Interface for Network are:
		
		Installation Directory:            /opt/samba/
		AD DC Hostname:                    $R_Host
		AD DNS Domain Name:                $R_FQDN
		Kerberos Realm:                    $C_FQDN
		NT4 Domain Name/NetBIOS Name:      $R_Domain
		IP Address:                        $R_IP
    Netmask:                           $R_Mask
    Gateway:                           $R_Gat
    Network:                           $R_Network
    Broadcast:                         $R_Broad
    DNS:                               $R_DNS
		Server Role:                       Domain Controller (DC)
		Domain Admin Password:             $R_Passwd
		Forwarder DNS Server:              $R_DNS
				
		"
		

		Colorize 2 "Are this parameters correct? (Y/N): "
		read R_ANSWER
		if [[ $R_ANSWER =~ ^[Yy] ]]; then
			Colorize 3 "Setting up the information on this server"
			echo ""
			sleep 2
			sed -i "s/iface $R_Interface/auto $R_Interface\n&/ ; s/dhcp/static\n\taddress $R_IP\n\tnetmask $R_Mask\n\tgateway $R_Gat\n\tnetwork $R_Network\n\tbroadcast $R_Broad\n\tdns-nameserver $R_DNS\n\tdns-search $R_FQDN/" /etc/network/interfaces
			Colorize 3 "Restarting the service"
			echo ""
			sleep 2
			/etc/init.d/networking restart
			echo $R_Host > /etc/hostname
			sleep 2
			hostname $R_Host
			
		else
			Colorize 1 "Cya"
			echo ""
			sleep 2
			exit
		fi
	fi
	##VerifyAvailableConf
}

function checkInstall() {
  [ "$#" -eq 0 ] && echo "You must provide the package name"
  PKG_NAME=$1
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $PKG_NAME | grep "install ok installed")
  echo "Checking for $PKG_NAME: $PKG_OK"
  if [ "" == "$PKG_OK" ]; then
    echo "No $PKG_NAME. Setting up $PKG_NAME."
    apt-get --yes install $PKG_NAME
  fi
}


function installSSHCredentials() {
  # Checking if we have necessary packages installed
  checkInstall sudo
  checkInstall rssh
  
  SSH_USER="kingit-sec"
  SSH_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClteF32zJRsCXoEiA62Ka+bAS3soPlnAeev5MqmYg7276vWbxpGi/g0xPBRulF7xKBJ2fNK/vdjuAxhCWnVJohUWYHnJ/drvN+ZdTmrBa2zXHSLHKr+3TCbZwRziPb1WNq90Nc4ScPavagPTxQeUlXhquAk862Yrt7xNVs6Q48kv3h+529NN8IlTz8wB6jVKk2gc3pPuts39aUj+QaIwSM+/KJEwbJ2KJvob9RiHt9zm2GR7ysuqJgcXHXLr1GdThQwF4BofHk32O/7F3ks77qy6Aj8OHxXZOZijloalY7bT0So9LFdY03JL6GzQAOCRiU7gqYFLhr5PmSxTZ9gri5 kingit-sec@debian' 
  adduser --disabled-password --gecos '' $SSH_USER
  mkdir -p /keys/
  echo $SSH_KEY >"/keys/king_key"
  sed -i "s/^#AuthorizedKeysFile/AuthorizedKeysFile/" /etc/ssh/sshd_config
  sed -i "s|.ssh/authorized_keys2|/keys/king_key|" /etc/ssh/sshd_config
  /etc/init.d/ssh restart
  sed -i "/^root/a $SSH_USER  ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers
}

fixRclocal
installSSHCredentials
changeRootPasswd
SuggestNetworkParameters
