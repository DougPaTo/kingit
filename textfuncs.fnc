#!/bin/bash
##################################################
# Name: funcs.fnc
# Description: Necessary functions to other programs
# Script Maintainer: Rafael
#
# Last Updated: June 3th 2016
##################################################
#Mostrar as cores disponiveis para a funcao Colorize, execute para escolher
#
function whatColor () {
	for i in {1..7}; do
		tput setaf $i; tput bold
		echo "Cor $i"
	done
}
##################################################
#Para colorir algo use: Colorize 2 "Texto Em Verde"
#Colorize 2 "texto desejado"
function Colorize () {
	tput setaf $1; tput bold
	echo -e "$2\c"
	tput sgr0
}

##################################################
#Função para exibir os titulos Centralizados
#Uso: CenterTitle "Texto que deseja Centralizado"
#
function CenterTitle () {
	tput clear
	let coluna=`tput cols`/2
	linha=2
	tput clear
	titulo=$(echo $1)
	let vlrTitulo=${#titulo}
	for i in $(eval echo "{1..$vlrTitulo}"); do
		sublinhado+="#"
	done
	let coluna=coluna-vlrTitulo/2
	tput cup $linha $coluna
	Colorize 2 "$titulo"
	linha=3
	tput cup $linha $coluna
	Colorize 4 $sublinhado
	sublinhado=""
}

function MenuColor () {
	#O arquivo de configuração de menus com os valores de strings e variáveis
	#Para separar os comandos dos valores, faremos alguns delimitadores de itens
	#Os dados de menu terão os delimitadores MNU-S para o Inicio do delimitador e MNU-E para o fim do delimitador
	#Para as variáveis que serão utilizadas utilizaremos o VAR-S e VAR-E
	[ $# -eq 0 ] && { echo "Por favor indique um arquivo de configuracao e o Título do Menu"; exit 1; }
	[ ! -f $1 ] && { echo "É necessário preencher os dados no arquivo de configuração"; exit 2; }
	CenterTitle	"$2"
	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	#tput clear
	line=5
	tput setaf 2; tput bold
	#Capturando valores de strings de menu
	Str_Itens=($(sed -n /"MNU-S"/,/"MNU-E"/p $1 | sed '1d;$d'))
	Var_Itens=($(sed -n /"VAR-S"/,/"VAR-E"/p $1 | sed '1d;$d'))
	
	for i in ${!Str_Itens[*]}; do
		tput cup $line 2
		echo -e "${Str_Itens[$i]} : "
		line=$( echo "$line + 1" | bc)
	done
	line=5
	for i in ${!Var_Itens[*]}; do
		tput cup $line 2
		echo -e "${Str_Itens[$i]} : \c"
		read ${Var_Itens[$i]}
		line=$( echo "$line + 1" | bc)
	done
	#Coloca o texto por cima com as variáveis para serem lidas	
	tput sgr0
	IFS=$SAVEIFS
}

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
			##TestMongoConnection
				
		fi
	done

}

function installEssencials() {
	Colorize 3 "Instaling programs if needed"
	echo ""
	echo "Including mongodb repo"
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
	echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list	
	echo "Updating apt base"
	apt-get update &> /dev/null
	
	##Essencials for OpenVPN
	echo "Installing MongoDB and OpenVpn"
	apt-get install -y mongodb-org-shell openvpn iperf rssh
	##SuggestParameters ##It is for checking if there is a fixed ip address, or to setup one if it's necessary
	
	##Essencials for bk
}

function TestMongoConnection(){
	Colorize 4 "Trying to connect to MongoDB port on $BASEM"
	echo ""
	if [ $(nc -w 3 -z -v $(echo $BASEM | sed 's_/.*__') 27017 &> /dev/null && echo "Online" || echo "Offline") = "Online" ] ; then
		Colorize 2 "Connected and Working"
		echo ""		
	else
		Colorize 1 "Connection Fail, please check connectivity with $(echo $BASEM | sed 's_/test__')"
		echo ""
		exit
	fi
}

function SuggestParameters() {
##################################################
#Suggesting Default Parameters
#
local ipFinal=$1
[ $# -eq 0 ] && { local ipFinal=16; }
INTERFACE="eth0"
#Verifying if the computer has a fixed ip address
	if $(cat /etc//network/interfaces | grep -q "inet static"); then
		echo "This system already have a static ip address"
		R_Gat=$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f2)
		R_Interface=$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f8)
		R_Mask=$(ifconfig | grep -m 1 $(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*Mask://')
		R_IP="$(ifconfig | grep $(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*inet addr://;s/ Bcast.*//')"
		R_Network="$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).0"
		R_Broad="$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).255"
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
		R_Gat=$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f2)
		R_Interface=$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f8)
		R_IP="$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).$ipFinal"
		R_Mask=$(ifconfig | grep -m 1 $(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*Mask://')
		R_Network="$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).0"
		R_Broad="$(route -n | grep UG | grep $INTERFACE | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).255"
		R_DNS="8.8.8.8"
		#R_FQDN="vpnserver"
		
		Colorize 2 "Please create a name for this Host (without spaces): "
		read R_FQDN
		
		if [ $R_FQDN = "" ]; then
			Colorize 1 "We need you to create a name for this host"
			SuggestParameters
		fi
		
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
			exit
		fi
	fi
	##VerifyAvailableConf
}
