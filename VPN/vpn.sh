#!/bin/bash
##################################################
# Name: vpn.sh
# Description: Install client and server and Verification of VPNs
# Script Maintainer: Rafael
#
# Versão: 0.7
# Last Updated: May 6th 2016
##################################################
###### 			VPNs Matriz e Obras		   ####### 
# 


#address to download the code: wget https://goo.gl/4sS4FU -O vpn.sh
## O que precisa ser feito
## Cadastrar Clientes
## Atribuir portas e listar portas disponiveis
## exportar configuracao - .conf - firewall e static.key
## testar conectividade e exibir configuracoes para clientes.


## Start Connectivity test
: << 'TASKS'
Verify Internet Connection
	Wait Until we verify the Internet Connection
Check DataBase Mongo to know about the ports available
	Trying to connect to the DataBase Centre
	Bring the information to the screen
	Select the last UDP Port Available to Connection and ask for confirmation
Test the UDP port Selected - netstat -t -u -p -l -e -n 
	nmap -p T:<PORT> kingit.ddnsking.com
	If there is no connectivity, ask the user to open the port on the router and try again
If the Connectivity could be made, continue to the next steps.
	Ask for some informations:
		Client's Name:
		Server's password:
	check if RSSH is installed
		If not install it
		
-What we need to know
		Client Network:
		
TASKS
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
wget goo.gl/klNlVy -O textfuncs.fnc
fi
sleep 3
source textfuncs.fnc

##################################################
###### Starting global variables
# 
#BASEM="kingit.ddnsking.com/kingit"
BASEM=192.168.0.50/test
BANCOM="vpn"
R_VPNSRV="kingit.ddnsking.com"

#mongo $BASEM --eval 'db.getCollectionNames()' #Verify if the collection exists
#mongo $BASEM --eval 'db.vpn.insert({"VPN_Range": "5100-5120"})'
#mongo $BASEM --eval 'printjson(db.'$BANCOM'.find({} ,{_id: 0, "VPN_Range": 1, "Report.TotalSize": 1}).sort({"Report.StartDate":-1}).pretty().shellPrint())'	

: <<'SCHEMA'
db.vpn.insert(
{
	"VPN_Address": "NoADDRESS", 
	"Client":{
		"Name": "NOCLIENT",
		"TUN": "'$R_TUN'",
		"ConIP": "'$R_CONIP'", 
		"Network": "'$R_NETWORK'", 
		"Port": "'$R_PORT'"
		}
}
)

SCHEMA

#Conection string with mongodb server and database

#############################################
#
function VerifyInternetCon(){
	tput cup 5 2
	Colorize 7 "Starting Internet Connection Tests"
	echo ""
	for i in $(ping -c2 8.8.8.8 | grep received | cut -d, -f2 | sed 's/^ //' | sed 's/ received//'); do
		if [ $i -eq 0 ]; then 
			Colorize 1 "No internet Connection, please verify and try again"
			echo ""
			break
		else
			Colorize 2 "Internet connection Verified - OK"
			echo ""
			TestMongoConnection
				
		fi
	done

}

function TestMongoConnection(){
	Colorize 4 "Trying to connect to MongoDB port on $BASEM"
	echo ""
	if [ $(nc -w 3 -z -v $(echo $BASEM | sed 's_/test__') 27017 &> /dev/null && echo "Online" || echo "Offline") = "Online" ] ; then
		Colorize 2 "Connected and Working"
		echo ""
		Colorize 4 "Verifying Connection to MongoDB"
		echo ""
		sleep 3
		FirstLoad
	else
		Colorize 1 "Connection Fail, please check connectivity with $(echo $BASEM | sed 's_/test__')"
		echo ""
		break
	fi
}

#mongo $BASEM --eval 'db.vpn.insert({"VPN_Range": "5100-5120"})'
##Calculate the ports
function FirstLoad() {
	Colorize 3 "Instaling programs if needed"
	echo ""
	echo "Updating apt base"
	apt-get update &> /dev/null
	echo "Installing MongoDB and OpenVpn"
	apt-get install -y mongodb-clients openvpn iperf rssh
##Verify if there is some data there
#Putting Fixed IP Address
SuggestParameters

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


##TEST UDP Connection

#first you need to stabilish a trusted connection between the client and the server
#to do this we can use one autodeploy key with the command ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
#then we need to create the trusted connection usind ssh with the command ssh-copy-id -i ~/.ssh/id_rsa.pub root@serverip_or_ddns

if [ ! -f ~/.ssh/id_rsa.pub ]; then
	echo "Creating ssh-key rsa" 
	ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
	echo "Creating Trusted Relationship between servers"
	ssh-copy-id -p3851 -i ~/.ssh/id_rsa.pub root@minerafa.pointto.us
fi

Colorize 5 "Starting UDP Port tests"
echo ""

for i in $(seq 5100 1 5120); do
	Colorize 6 "Testing Port $i: \c"
	#echo $(nc -w 3 -z -v  $(echo $WanIP | sed 's_/test__') $i &> /dev/null && echo "Online" || echo "Offline")
	 iperf -s -p $i -u &> /dev/null &
	if $(ssh -p3851 root@minerafa.pointto.us "iperf -c minerafa.pointto.us -u -p $i -b 10M 2> /dev/null | grep -q 'Server Report'"); then
		echo "Online"
	else
		echo "Offline"
	fi
done
	killall iperf

##
: <<'test'
if [ $(mongo $BASEM --eval 'db.vpn.find({"VPN_Address": "NoADDRESS"}, {_id: 0}).limit(1).shellPrint()' | grep VPN_Address | sed -n 's/.*\(VPN_Address\).*/\1/p') ]; then
	Colorize 2 "Data Exists, we are ready to go"
	echo ""
	sleep 3
	SuggestParameters
else
	Colorize 4 "Creating fist records on database..."
	echo ""
	sleep 5 
	R_NETWORK="0.0.0.0/24"
	for i in $(seq $PortStart 1 $PortEnd);do
		R_PORT=$i
		if [ $i -lt 5110 ]; then
			R_TUN="tun$(echo $i | sed 's/510//')"
			R_CONIP="122.122.$(echo $i | sed 's/510//').2"
		else
			R_TUN="tun$(echo $i | sed 's/51//')"
			R_CONIP="122.122.$(echo $i | sed 's/51//').2"
		fi
		mongo $BASEM --eval 'db.vpn.insert({"VPN_Address": "NoADDRESS", "Client":{"Name": "NOCLIENT","TUN": "'$R_TUN'","ConIP": "'$R_CONIP'", "Network": "'$R_NETWORK'", "Port": "'$R_PORT'"}})'
	done
	FirstLoad
fi
test

}

function SuggestParameters() {
##################################################
#Suggesting Default Parameters
#

#Verifying if the computer has a fixed ip address
	if $(cat /etc//network/interfaces | grep -q "inet static"); then
		echo "This system already have a static ip address"
		R_Gat=$(route -n | grep UG | tr -s ' ' | cut -d' ' -f2)
		R_Interface=$(route -n | grep UG | tr -s ' ' | cut -d' ' -f8)
		R_Mask=$(ifconfig | grep $(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*Mask://')
		R_IP="$(ifconfig | grep $(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*inet addr://;s/ Bcast.*//')"
		R_Network="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).0"
		R_Broad="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).255"
		R_DNS="8.8.8.8"
		R_FQDN="cat /etc/hostname"
		
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
		R_Gat=$(route -n | grep UG | tr -s ' ' | cut -d' ' -f2)
		R_Interface=$(route -n | grep UG | tr -s ' ' | cut -d' ' -f8)
		R_IP="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).16"
		R_Mask=$(ifconfig | grep $(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*Mask://')
		R_Network="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).0"
		R_Broad="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).255"
		R_DNS="8.8.8.8"
		#R_FQDN="vpnserver"
		
		echo "
		Suggested Parameters in Interface $R_Interface for Network are:
		
		IP Address: $R_IP
		Netmask: $R_Mask
		Gateway: $R_Gat
		Network: $R_Network
		Broadcast: $R_Broad
		DNS: $R_DNS
		Domain: $R_FQDN
		
		"
		Colorize 2 "Are this parameters correct? (Y/N): "
		read R_ANSWER
		if [ $R_ANSWER = "Y" ]||[ $R_ANSWER = "y" ]; then
			Colorize 3 "Setting up the information on this server"
			echo ""
			sleep 2
			sed -i "s/iface eth0/auto eth0\n&/ ; s/dhcp/static\n\taddress $R_IP\n\tnetmask $R_Mask\n\tgateway $R_Gat\n\tnetwork $R_Network\n\tbroadcast $R_Broad\n\tdns-nameserver $R_DNS\n\tdns-search $R_FQDN/" /etc/network/interfaces
			Colorize 3 "Restarting the service"
			echo ""
			sleep 2
			/etc/init.d/networking restart
			echo $R_FQDN > /etc/hostname
			sleep 2
			hostname $R_FQDN
			
		else
			Colorize 1 "Bye Bye"
			echo ""
			sleep 2
			return
		fi
	fi
	##VerifyAvailableConf
}

##################################################
#Set the number of available ports to connect
#
VPN_Ports=($(seq 5100 1 5120))

function VerifyAvailableConf() {
	##################################################
	#Connection to mongoDB to check available configurations
	#
	#mongo $BASEM --eval 'db.vpn.find({"Client.Name": "NOCLIENT"}, {_id: 0, "Client.TUN": 1}).limit(1).shellPrint()'
	V_Port=$(mongo $BASEM --eval 'db.vpn.find({"Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "Port" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	V_Tun=$(mongo $BASEM --eval 'db.vpn.find({"Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "TUN" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	V_ConIP=$(mongo $BASEM --eval 'db.vpn.find({"Client.Name": "NOCLIENT"}, {_id: 0}).limit(1).pretty().shellPrint()' | grep "ConIP" | cut -d: -f2 | sed 's/^ //;s/"//g;s/,//')
	
	Colorize 2 "We need to know what is the address of the VPN Server [kingit.ddnsking.com]: "
	read R_VPNSRV
	if [ R_VPNSRV=="" ]; then
		R_VPNSRV="kingit.ddnsking.com"
	fi
	CenterTitle "Available VPN Connection"
	Colorize 6 "
	
	Vpn server Address: $R_VPNSRV
	Port of connection: $V_Port
	Tun Virtual adaptor: $V_Tun
	Connection IP: $V_ConIP
	Network: $R_Network
	Subnet Mask: $R_Mask
	
	
	Any other needed information are going to be taken from the system.
	
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
	if [ -z ${Created[@]} ] ;then
		echo "Any VPNs Created"
		read -p "Press [Enter] to create the the configuration for Port $V_Port here"
		configServer
		configClient
		#Adjusting Client configs to be server configs
		cat confs/client/acesso_$V_Port.conf | sed 's/remote.*//;/^$/d' >> confs/server/acesso_$(echo $V_Port).conf
		tmp_ip=$(echo $V_ConIP | sed 's/.$/1/')
		#echo $tmp_ip
		#echo $V_ConIP
		cat confs/server/startsrv_$(echo $V_Port).sh | sed "s/$tmp_ip/$V_ConIP/g;s/server/client/" >>  confs/client/startsrv_$(echo $V_Port).sh
		Colorize 3 "VPN Configuration for server and client done"
		echo ""
	else
		Colorize 3 "These are the VPNs configs in this server"
		echo ""
		echo ${Created[@]}
	fi
	
	
:<<'Nothing'	
	
Nothing
	 
}

function configServer(){
TunFile=confs/server/startsrv_$V_Port.sh

## Criar as interfaces
echo "openvpn --mktun --dev $V_Tun" >> $TunFile

#Definindo IP da interface 
echo "ifconfig $V_Tun $(echo $V_ConIP | sed 's/.$/1/') netmask 255.255.255.0 promisc up" >> $TunFile

#Abrir firewall para tun0
echo "iptables -t nat -A POSTROUTING -j MASQUERADE" >> $TunFile
echo "iptables -I INPUT -p udp --dport $V_Port -j ACCEPT" >> $TunFile
echo "iptables -I FORWARD -i eth0 -o $V_Tun -j ACCEPT" >> $TunFile
echo "iptables -I FORWARD -i $V_Tun -o eth0 -j ACCEPT" >> $TunFile

echo "sleep 5" >> $TunFile
#route add -net 10.0.0.0 netmask 255.255.0.0 gw 10.5.76.16 #- Linux
#route -p add 10.0.99.198 mask 255.255.255.255 10.5.76.16 - Windows
echo "openvpn --config conf/server/acesso_$(echo $V_Port).conf &" >> $TunFile

echo "sleep 5" >> $TunFile
#Criando rotas para a Obra
echo "route add -net $R_Network netmask $R_Mask gw $(echo $V_ConIP | sed 's/.$/1/') dev $V_Tun" >> $TunFile
#route add -net 10.5.63.0 netmask 255.255.255.0 gw 10.3.0.2 #Este sera o novo padrao da obra

#Importante sysctl.conf
#alterar o portfoward
#depois sysctl -p

}

function adjustPortForward(){
	echo "Making some adjustments on port forward"
	sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
	sysctl -p
}

function firewall(){
FireFile=fire/firewall_${VPN_Ports[$1]}.sh
	
#Permitir comunicacao atraves da rede
#echo "iptables -t nat -A POSTROUTING -j MASQUERADE" >> $FireFile
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
echo "secret static.key" >> $ConfFile

#push "route 10.0.0.0 255.255.0.0"
#route 192.168.253.0 255.255.255.0

}


function CreateNewVPNServer() {
	echo ""
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
		1) echo "  VPN Server Creator"; sleep 3; tput clear; R_FQDN="vpnserver"; VerifyInternetCon ;;
		2) echo "  VPN Client Creator"; sleep 3; tput clear; R_FQDN="vpnclient"; exit ;;
		9) echo "  Valew Falow" ; exit;;
		*) echo "  Please choose a valid option"; sleep 3 ; MenuVPN ;;
	esac
}

function iniciavpn(){

#Iniciando a VPN
#sleep 5
openvpn --config barueri.conf &
openvpn --config sumare.conf &
openvpn --config iamspe.conf &
openvpn --config ersaude.conf &

}



#CriaConfigs
#VerifyAvailable
#---VerifyInternetCon
#MongoDbConnection
#FirstLoad
#TestMongoConnection
#whatColor
#SuggestParameters
#VerifyAvailableConf
MenuVPN
