#!/bin/bash
##################################################
# Name: vpn.sh
# Description: Install client and server and Verification of VPNs
# Script Maintainer: Rafael
#
# Versão: 0.1
# Last Updated: April 19th 2016
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



: <<'TAREFAS'
-- Servidor OpenVpn--
Range of Ports: 5100 - 5120


-- Clientes Kingit --
01. Engeform Matriz
02. Barueri
03. A3
04. Brasilandia
05. Iamspe
06. Sumare
07. Eremim
08. Expomus
09. Embu
10. ITI7
11. PEC
12. Consorcio
13. ER Saude

-- Recursos --
Rafael 
	- Desenvolvimento - Produto - Servidores Linux Samba4
	- Desenvolvimento - Produto - Interligação de filiais VPN
	- Desenvolvimento - Produto - Virtualização
	- Desenvolvimento - Produto - Firewall
	- Desenvolvimento - Produto - Backup
	- Desenvolvimento - Produto - Versionamento
	- Desenvolvimento - Produto - Relatório Gerencial
	- Desenvolvimento - Automações de processos
	- Administração - Planejamento de Ações
	- Financeiro - Cobrança - Emissão de Notas fiscais
	- Financeiro - Cobrança - Emissão de Boletos
	- Financeiro - Pagamento - Contas da Empresa
	- Financeiro - Pagamento - Salários
	- Financeiro - Pagamento - Impostos
	- Atendimento - Implantação de Infraestrutura Nova
	- Atendimento - Suporte - Telefônico
	- Atendimento - Suporte aos colaboradores
	- Atendimento - Suporte - Onsite - N3
	- Atendimento - Suporte - Teamviewer
	
Douglas
	- Atendimento - Suporte - Onsite - N1
	- Atendimento - Suporte - Teamviewer
	- Atendimento - Suporte - Telefonico
	- Administração - Relatórios
	- Desenvolvimento - Automação - Excel
	
Erbely
	- Comercial - Captação de clientes
	- Atendimento - Suporte - Onsite - N1
	- Atendimento - Implantação de Infraestrutura Nova
	- Financeiro - Cobrança - Envio de Relatórios e velores
	
Yudy
	- Atendimento - Suporte - Onsite - N1
	- Monitoramento - Hardware e Processos
	
André
	- Atendimento - Suporte - Onsite - N1
	
Samantha
	- Atendimento - Suporte - Onsite - N1
	
TAREFAS

: <<'VPN'
O vou precisar para fazer isto funcionar corretamente?

1 Saber quantas portas estão disponíveis no centralizador
2 conseguir acesso direto e seguro por ssh entre os servidores
3 Criar arquivos de configuração para o servidor e para o cliente
4 adicionar informações de uso na base de dados
5 consultar informações de conexão da base de dados e realizar testes de conexão.
6 Criar site para consultar informações facilmente.


VPN

#Conection string with mongodb server and database

#############################################
#
function VerifyInternetCon(){
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
	Colorize 4 "Trying to connect to MongoDB on $BASEM"
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


#BASEM="kingit.ddnsking.com/kingit"
BASEM=192.168.0.34/test
BANCOM="vpn"

#mongo $BASEM --eval 'db.getCollectionNames()' #Verify if the collection exists
#mongo $BASEM --eval 'db.vpn.insert({"VPN_Range": "5100-5120"})'
#mongo $BASEM --eval 'printjson(db.'$BANCOM'.find({} ,{_id: 0, "VPN_Range": 1, "Report.TotalSize": 1}).sort({"Report.StartDate":-1}).pretty().shellPrint())'	

: <<'SCHEMA'
db.vpn.insert(
{
	"VPN_Range": "5100-5120", 
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

#mongo $BASEM --eval 'db.vpn.insert({"VPN_Range": "5100-5120"})'
##Calculate the ports
function FirstLoad() {
	Colorize 3 "Instaling programs needed"
	echo ""
	echo "Updating apt base"
	apt-get update &> /dev/null
	echo "Installing MongoDB and OpenVpn"
	apt-get install mongodb-clients openvpn
##Verify if there is some data there
if [ $(mongo $BASEM --eval 'db.vpn.find({"VPN_Range": "5100-5120"}, {_id: 0}).limit(1).shellPrint()' | grep VPN_Range | sed -n 's/.*\(VPN_Range\).*/\1/p') ]; then
	Colorize 2 "Data Exists, we are ready to go"
	echo ""
	sleep 3

else
	Colorize 4 "Creating fist records on database..."
	echo ""
	sleep 5 
	R_NETWORK="0.0.0.0/24"
	for i in $(seq 5100 1 5120);do
		R_PORT=$i
		if [ $i -lt 5110 ]; then
			R_TUN="tun$(echo $i | sed 's/510//')"
			R_CONIP="122.122.$(echo $i | sed 's/510//').2"
		else
			R_TUN="tun$(echo $i | sed 's/51//')"
			R_CONIP="122.122.$(echo $i | sed 's/51//').2"
		fi
		mongo $BASEM --eval 'db.vpn.insert({"VPN_Range": "5100-5120", "Client":{"Name": "NOCLIENT","TUN": "'$R_TUN'","ConIP": "'$R_CONIP'", "Network": "'$R_NETWORK'", "Port": "'$R_PORT'"}})'
	done
fi


}

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

function SuggestParameters() {
##################################################
#Suggesting Default Parameters
#
	#Getting the ip address
	R_Gat=$(route -n | grep UG | tr -s ' ' | cut -d' ' -f2)
	R_IP="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).16"
	R_Mask=$(ifconfig | grep $(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3) | sed 's/.*Mask://')
	R_Network="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).0"
	R_Broad="$(route -n | grep UG | tr -s ' ' | cut -d' ' -f 2 | cut -d. -f1-3).255"
	R_DNS="8.8.8.8"
	R_FQDN="vpnclient"
	
	echo "
	Suggested Parameters for Network are:
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
	

}

##################################################
#Set the number of available ports to connect
#
VPN_Ports=($(seq 5100 1 5120))

function VerifyAvailable() {
	Created=($(ls confs))
	if [ -z ${Created[@]} ] ;then
		echo "Sem VPNs Criadas"
	else
		echo ${Created[@]}
	fi
	 
}

function CriaConfigs() {
	
	for i in ${!VPN_Ports[@]};do
		configServer $i
		configClient $i
	done
}

function configServer(){
TunFile=confs/tunel_${VPN_Ports[$1]}.sh

## Criar as interfaces
echo "openvpn --mktun --dev tun$1" >> $TunFile

#Definindo IP da interface 
echo "ifconfig tun$1 122.122.$1.1 netmask 255.255.255.0 promisc up" >> $TunFile

sleep 5
#Criando rotas para a Obra
echo "route add -net $R_IP netmask $R_MASK gw 122.122.$1.2" >> $TunFile
#route add -net 10.5.63.0 netmask 255.255.255.0 gw 10.3.0.2 #Este sera o novo padrao da obra

#Abrir firewall para tun0
echo "iptables -I INPUT -p udp --dport ${VPN_Ports[$1]} -j ACCEPT" >> $TunFile
echo "iptables -I FORWARD -i eth0 -o tun$1 -j ACCEPT" >> $TunFile
echo "iptables -I FORWARD -i tun$1 -o eth0 -j ACCEPT" >> $TunFile

#route add -net 10.0.0.0 netmask 255.255.0.0 gw 10.5.76.16 - Linux
#route -p add 10.0.99.198 mask 255.255.255.255 10.5.76.16 - Windows

#Importante sysctl.conf
#alterar o portfoward
#depois sysctl -p

#AjustesIPFixo
}

function firewall(){
FireFile=fire/firewall_${VPN_Ports[$1]}.sh
	
#Permitir comunicacao atraves da rede
#echo "iptables -t nat -A POSTROUTING -j MASQUERADE" >> $FireFile
}

function configClient(){
ConfFile=confs/acesso_${VPN_Ports[$1]}.conf

echo "dev tun$1" >> $ConfFile
echo "proto udp" >> $ConfFile
echo "port ${VPN_Ports[$1]}" >> $ConfFile
echo "keepalive 10 120" >> $ConfFile
echo "comp-lzo" >> $ConfFile
echo "persist-key" >> $ConfFile
echo "persist-tun" >> $ConfFile
echo "float" >> $ConfFile
echo "ifconfig 122.122.$1.1 122.122.$1.2" >> $ConfFile
echo "secret static.key" >> $ConfFile

#push "route 10.0.0.0 255.255.0.0"
#route 192.168.253.0 255.255.255.0

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
#VerifyInternetCon
#MongoDbConnection
#FirstLoad
TestMongoConnection
#whatColor

#SuggestParameters
