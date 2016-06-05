#!/bin/bash
##################################################
# Name: vpn.sh
# Description: Install client and server VPNs
# Script Maintainer: Rafael
#
# Versão: 1.5
# Last Updated: June 1st 2016
##################################################
###### 			VPNs Matriz e Obras		   ####### 
# 


#address to download the code: wget https://goo.gl/4sS4FU -O vpn.sh
: << 'Howto'
You need to open the range os ports from 5100 to 5120 all UDP on your router
pointing to the ip ending in 16 for the server side, and the port 5100 TCP 
pointing to the same address

On the client side nothing is needed

Is very important to download the last version of mongo to ensure the best compatibility possible

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

sudo apt-get update

sudo apt-get install -y mongodb-org

Howto
		
##################################################
#Include source file with text functions
#
echo "Verifying Dependencies"
echo ""
sleep 2
if [ ! -f textfuncs.fnc ]; then
echo "Downloading configuration file"
echo ""
sleep 2
wget goo.gl/4ATfHz -O textfuncs.fnc
fi
sleep 3
source textfuncs.fnc

##################################################
###### Starting global variables
# 
INTERFACE="eth"
BASEM="kingit.ddnsking.com/kingit"
BANCOM="vpn"
MUser="kingit"
MPass="MK1m0n00$"
DefaultPortSSH=5100
TestSrvPort=5245 ##Test server
TestSrvAddress="kingit.ddnsking.com" ##Test server
#mongo $BASEM -u $MUser -p $MPass -u $MUser -p $MPass --eval 'db.getCollectionNames()' #Verify if the collection exists
#mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.insert({"VPN_Range": "5100-5120"})'
#mongo $BASEM -u $MUser -p $MPass --eval 'printjson(db.'$BANCOM'.find({} ,{_id: 0, "VPN_Range": 1, "Report.TotalSize": 1}).sort({"Report.StartDate":-1}).pretty().shellPrint())'	

: <<'SCHEMA'

'db.vpn.insert({
	"VPN_Address": "'$R_DDNS'", 
	"ServerNetwork": "'$R_Network'", 
	"ServerMask": "'$R_Mask'", 
	"Client":{"Name": "NOCLIENT",
	"TUN": "'$R_TUN'", 
	"ConIP": "'$R_CONIP'", 
	"Network": "'$R_NETWORK'", 
	"Mask": "'$R_MASK'", 
	"Port": "'$R_PORT'"}
	})'
SCHEMA

#Conection string with mongodb server and database

#############################################
#

function InstallVPN() {
	VerifyInternetCon
	TestMongoConnection
	installEssencials
	SuggestParameters
	if [ $T_SRV = "vpnserver" ]; then	
		sed -i 's|^exit 0|cd /root/confs/server/\n&|' /etc/rc.local
		FirstLoad
	else
		listServerOptions
		exit
	fi
	
}

#mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.insert({"VPN_Range": "5100-5120"})'
##Calculate the ports
function FirstLoad() {
PortStart=5100
PortEnd=5120
WanIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo "
	It's necessary to forward the trafic of the range of ports
	between $PortStart and $PortEnd to your VPN Server IP: $R_IP 
	in your router in order for this server to work.
	Please Make the changes and press the button to test if the 
	ports are properly opened.
	
	We are going to test the access for this ports 
	from your external IP: $WanIP
	"
	
read -p "Press [Enter] to continue "
testUDP ##Call the function
}

function testUDP() {
##TEST UDP Connection

#first you need to stabilish a trusted connection between the client and the server
#to do this we can use one autodeploy key with the command ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
#then we need to create the trusted connection usind ssh with the command ssh-copy-id -i ~/.ssh/id_rsa.pub root@serverip_or_ddns

if [ ! -f ~/.ssh/id_rsa.pub ]; then #Verify if you already setup a ssh-key
	echo "Creating ssh-key rsa" 
	ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
	echo "Creating Trusted Relationship between servers"
	ssh-copy-id -p$TestSrvPort -i ~/.ssh/id_rsa.pub root@$TestSrvAddress
fi

Colorize 5 "Starting UDP Port tests"
echo ""

for i in $(seq 5100 1 5120); do
	Colorize 6 "Testing Port $i: \c"
	#echo $(nc -w 3 -z -v  $(echo $WanIP | sed 's_/test__') $i &> /dev/null && echo "Online" || echo "Offline")
	 iperf -s -p $i -u &> /dev/null &
	 Ecount=0
	 tput sc
	for testn in $(seq 1 10); do
		if $(ssh -p$TestSrvPort root@$TestSrvAddress "iperf -c $WanIP -u -p $i -b 10M 2> /dev/null | grep -q 'Server Report'"); then
			tput rc
			echo " - Tested - $testn time - Online"
			break
		else
			tput rc
			Ecount=$(($Ecount + 1))
			echo " - Tested - $testn time - Offline"
			sleep 2
			if [ $Ecount -gt 9 ]; then
				Colorize 1 "We had too many errors on the test of port $i"
				echo ""
				read -p "Test your internet connection and try again Press [Enter]"
				killall iperf
				exit
			fi
		fi
	done		
done
killall iperf
TestDDNS ##Call the function to test the ddns
}

function TestDDNS(){
##With the server perfectly operational, the next step is setting up a DDNS name for it
	Colorize 1 "
	Please setup a ddns address for the server or use your
	ISP fixed IP address, your currently WAN address is: $WanIP
	"
	Colorize 8 "Please type your ddns address for testing: "
	read R_DDNS
	##Test if the DDNS is set correctly
	if $(ping -c1 $R_DDNS | grep -q $WanIP); then
		Colorize 2 "DDNs working correctly"
		echo ""
		sleep 5
		VerifyMongoDB
	else	
		echo "DDNS doesn't match with the WAN Address"
		read -p "Fix it and press [Enter] to test again "
		TestDDNS
	fi
}

function VerifyMongoDB() {
	Colorize 7 "Verifying Mongo DataBase"
	echo ""
##

if [ $(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"VPN_Address": '$R_DDNS'}, {_id: 0}).limit(1).shellPrint()' | grep VPN_Address | sed -n 's/.*\(VPN_Address\).*/\1/p') ]; then
	Colorize 2 "This Server is already on the DataBase"
	echo ""
	sleep 3
	#SuggestParameters
else
	Colorize 4 "Creating fist records on database..."
	echo ""
	sleep 5 
	R_NETWORK="0.0.0.0"
	R_MASK="255.255.255.0"
	for i in $(seq $PortStart 1 $PortEnd);do
		R_PORT=$i
		if [ $i -lt 5110 ]; then
			R_TUN="tun$(echo $i | sed 's/510//')"
			R_CONIP="122.122.$(echo $i | sed 's/510//').2"
		else
			R_TUN="tun$(echo $i | sed 's/51//')"
			R_CONIP="122.122.$(echo $i | sed 's/51//').2"
		fi
		mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.insert({"VPN_Address": "'$R_DDNS'", "ServerNetwork": "'$R_Network'", "ServerMask": "'$R_Mask'", "Client":{"Name": "NOCLIENT","TUN": "'$R_TUN'","ConIP": "'$R_CONIP'", "Network": "'$R_NETWORK'", "Mask": "'$R_MASK'", "Port": "'$R_PORT'"}})'
	done
	#VerifyMongoDB
	#VerifyAvailableConf
	adjustPortForward
	Colorize 5 "Verifying static.key"
	echo ""
	if [ ! -f confs/static.key ]; then
		if [ ! -d confs ]; then
			echo "Any directories found, lets create then..."
			sleep 2
			mkdir -p confs/server
			mkdir -p confs/client
		fi
		Colorize 2 "Adjustments on RSSH, changing port to 5100"
		echo ""
		sleep 2
		sed -i "s/^Port 22/Port 5100/;s/^PermitRootLogin/#&/" /etc/ssh/sshd_config
		/etc/init.d/ssh restart
		
		cd confs/
		openvpn --genkey --secret static.key
		echo "Exporting Static Key to remote Server"
		ssh -p$TestSrvPort root@$TestSrvAddress "mkdir -p vpns/$R_DDNS" ##Making dir to store the static.key
		scp -P$TestSrvPort static.key root@$TestSrvAddress:~/vpns/$R_DDNS/ ##Placing static.key on the remote server
		cd 
		echo "Static.key created, your server are ready to go!"
		Colorize 2 "Server restarting in 15 seconds"
		sleep 15
		reboot
	else
		echo "Static.key already created for this server"
	fi
fi

}

function gettingStatic() {
	if [ ! -f confs/static.key ]; then
		Colorize 1 "It's Necessary to download the static.key from a trusted server, please insert the password!"
		echo""
		scp -P$TestSrvPort root@$TestSrvAddress:~/vpns/$R_VPNSRV/static.key ~/confs/ ##Placing static.key on the remote server
	fi
}

function sendServerConfs() {
	Colorize 3 "It's time to send the confs to the server, please insert the password!" 
	echo""
	cd confs/server
	scp -P$DefaultPortSSH acesso_$V_Port.conf startsrv_$(echo $V_Port).sh root@$R_VPNSRV:/root/confs/server/
	
	echo "Including Server VPN on the startup"
	sleep 3
	ssh -p$DefaultPortSSH root@$R_VPNSRV "sed -i 's|^exit 0|sh startsrv_$V_Port.sh \&\n&|' /etc/rc.local"
	
}

function listServerOptions() {
	varOpt=($(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"Client.Name": "NOCLIENT"}, {_id: 0, VPN_Address: 1}).limit(1).pretty().shellPrint()' | grep { | sed 's/{ //;s/ }//' | cut -d: -f2 | sed 's/ //g;s/"//g;s/,//'))

	CenterTitle "These are the servers available choose one: "
	echo ""
	for opt in $(seq 0 ${#varOpt[*]}); do
		if [ ! ${varOpt[$opt]} = "" ]; then
			echo "$(( $opt )). ${varOpt[$opt]}"
		fi
	done
		echo "9. Exit"
		echo ""
	read R_srvC

	for ((i = 0; i < ${#varOpt}; i++)); do
		if [[ ${varOpt[$i]} = ${varOpt[$R_srvC]} ]]; then
			R_VPNSRV=${varOpt[$i]}
			VerifyAvailableConf
			break
		fi
	done
		
	if ((i == ${#varOpt})); then
		echo "Please choose a valid option" ; listServerOptions
	fi
	if (( $R_srvC == 9 )); then
		return exit
	fi
}


function VerifyAvailableConf() {
	##################################################
	#Connection to mongoDB to check available configurations
	#
	#mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"Client.Name": "NOCLIENT"}, {_id: 0, "Client.TUN": 1}).limit(1).shellPrint()'
	V_Port=$(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"VPN_Address": "'$R_VPNSRV'", "Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "Port" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	V_Tun=$(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"VPN_Address": "'$R_VPNSRV'", "Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "TUN" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	V_ConIP=$(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"VPN_Address": "'$R_VPNSRV'", "Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "ConIP" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	V_SNet=$(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"VPN_Address": "'$R_VPNSRV'", "Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "ServerNetwork" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	V_SMask=$(mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.find({"VPN_Address": "'$R_VPNSRV'", "Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "ServerMask" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	
	#Colorize 2 "We need to know what is the address of the VPN Server [kingit.ddnsking.com]: "
	#read R_VPNSRV
	#if [ R_VPNSRV="" ]; then
	#	R_VPNSRV="kingit.ddnsking.com"
	#fi
	CenterTitle "Available VPN Connection"
	Colorize 6 "
	
	Vpn server Address: $R_VPNSRV
	Port of connection: $V_Port
	Tun Virtual adaptor: $V_Tun
	Connection IP: $V_ConIP
	Network: $R_Network
	Subnet Mask: $R_Mask
	
	"
	read -p " Press [Enter] to continue"
	echo "Lets check for folders"
	sleep 3
	if [ ! -d confs ]; then
		echo "Any directories found, lets create then..."
		sleep 2
		mkdir -p confs/server
		mkdir -p confs/client
	fi
	echo "Directories Created, Lets check if we have any VPN created there."
	sleep 2
	Created=($(ls confs/server/))
	if [ ${#Created[@]} -lt 1 ] ;then
		echo "Any VPNs Created"
		read -p "Press [Enter] to create the configuration for Port $V_Port here"
		configServer
		configClient
		#Adjusting Client configs to be server configs
		tmp_ip=$(echo $V_ConIP | sed 's/.$/1/')
		cat confs/client/acesso_$V_Port.conf | sed "s/remote.*//;/^$/d;s/ifconfig.*/ifconfig $tmp_ip $V_ConIP/" >> confs/server/acesso_$V_Port.conf
		#echo $tmp_ip
		#echo $V_ConIP
		cat confs/client/startsrv_$(echo $V_Port).sh | sed "s/$V_ConIP/$tmp_ip/g;s/route add -net $V_SNet netmask $V_SMask gw $(echo $V_ConIP | sed 's/.$/1/') dev $V_Tun/route add -net $R_Network netmask $V_SMask gw $V_ConIP dev $V_Tun/" >>  confs/server/startsrv_$(echo $V_Port).sh
		Colorize 3 "VPN Configuration for server and client done"
		echo ""
		##Record information on DataBase
		Colorize 7 "Recording information on DataBase"
		echo ""
		mongo $BASEM -u $MUser -p $MPass --eval 'db.vpn.update({"Client.Port": "'$V_Port'"}, {$set: {"Client.Name": "'$R_FQDN'", "Client.Network": "'$R_Network'", "Client.Mask": "'$R_Mask'"}})'
		echo "Data inserted sucessfully"
		adjustPortForward
		gettingStatic
		sendServerConfs
		Colorize 2 "Server Completely Ready, restarting in 15 seconds"
		sleep 15
		reboot
	else
		Colorize 3 "These are the VPNs configs in this server"
		echo ""
		echo ${Created[@]}
	fi
	
}

function configServer(){
TunFile=confs/client/startsrv_$V_Port.sh

## Criar as interfaces
echo "openvpn --mktun --dev $V_Tun" >> $TunFile

#Definindo IP da interface 
echo "ifconfig $V_Tun $V_ConIP netmask 255.255.255.0 promisc up" >> $TunFile

#Abrir firewall para tun0
echo "iptables -t nat -A POSTROUTING -j MASQUERADE" >> $TunFile
echo "iptables -I INPUT -p udp --dport $V_Port -j ACCEPT" >> $TunFile
echo "iptables -I FORWARD -i eth0 -o $V_Tun -j ACCEPT" >> $TunFile
echo "iptables -I FORWARD -i $V_Tun -o eth0 -j ACCEPT" >> $TunFile

echo "sleep 5" >> $TunFile
#route add -net 10.0.0.0 netmask 255.255.0.0 gw 10.5.76.16 #- Linux
#route -p add 10.0.99.198 mask 255.255.255.255 10.5.76.16 - Windows
echo "openvpn --config acesso_$(echo $V_Port).conf &" >> $TunFile

echo "sleep 5" >> $TunFile
#Criando rotas para a Obra
echo "route add -net $V_SNet netmask $V_SMask gw $(echo $V_ConIP | sed 's/.$/1/') dev $V_Tun" >> $TunFile
#route add -net 10.5.63.0 netmask 255.255.255.0 gw 10.3.0.2 #Este sera o novo padrao da obra

echo "Including VPN on the startup"
sleep 3
sed -i "s|^exit 0|cd /root/confs/client/\nsh startsrv_$V_Port.sh\n&|" /etc/rc.local
}

function adjustPortForward(){
	echo "Making some adjustments on port forward"
	sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
	sysctl -p
}

function configClient(){
ConfFile=confs/client/acesso_$V_Port.conf

echo "remote $R_VPNSRV" >> $ConfFile
echo "dev $V_Tun" >> $ConfFile
echo "proto udp" >> $ConfFile
echo "port $V_Port" >> $ConfFile
echo "keepalive 10 120" >> $ConfFile
echo "comp-lzo" >> $ConfFile
echo "persist-key" >> $ConfFile
echo "persist-tun" >> $ConfFile
echo "float" >> $ConfFile
echo "ifconfig $V_ConIP $(echo $V_ConIP | cut -d. -f1-3).1" >> $ConfFile
echo "secret ../static.key" >> $ConfFile

}

function MenuVPN() {
		CenterTitle "VPN Deploy System"
		echo ""
		tput cup 5 2
		Colorize 6 "1. Create a new VPN Server"
		tput cup 6 2
		Colorize 6 "2. Configure a VPN Client here"
		tput cup 7 2
		Colorize 6 "9. Quit"
		tput cup 9 2
		Colorize 3 "Please type the number of your choice: "
		read R_MVPN
		
		case $R_MVPN in
		1) echo "  VPN Server Creator"; sleep 3; tput clear; T_SRV="vpnserver"; InstallVPN ;;
		2) echo "  VPN Client Creator"; sleep 3; tput clear; T_SRV="vpnclient"; InstallVPN ;;
		9) echo "  Valew Falow" ; exit;;
		*) echo "  Please choose a valid option"; sleep 3 ; MenuVPN ;;
	esac
}

MenuVPN
