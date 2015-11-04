#!/bin/bash
##################################################
# Name: casdastros_bkp
# Description: Input of data on databse db_backups
# Script Maintainer: Rafael
#
# Versão: 1.0
# Last Updated: October 26th 2015
##################################################
###### Cadastros Backup ####### 
# 
: <<'COMENT'
To allow remote access to root
connect to mysql:

 GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;
 Edit /etc/mysql/my.cnf
 and comment:
 bind-address = 127.0.0.1 to #bind-address = 127.0.0.1
 
 #Sistema para chave publica e Chave privada.
 To create the Keys use the command:
 
 ssh-keygen -t rsa
 
 To install the public Key on remote host use
 
 $ ssh-copy-id -i ~/.ssh/id_rsa.pub login@servidor
 
 usuario criado no 10.0.99.76 - backup senha Eng123Form
 
 Fazer backup da base
 
 mysqldump db_backups > db_backups_esquema.sql
 
 Voltar o backup da base
 
 mysql -ubackup -h 10.0.99.76 -pEng123Form -e 'create database db_backups'
 mysql -ubackup -h 10.0.99.76 -pEng123Form db_backups < db_backups_esquema.sql
  
COMENT

##Cadastro de dados principais para o sistema##
#Inclui base para textos
source textfuncs.fnc

#Inicia Variaveis para Conexão e Comandos SQL na base.
varMSQLC='mysql -ubackup -h10.0.99.76 -pEng123Form -Ddb_backups -B -N -e' #Mostra apenas os Dados
varMSQLCT='mysql -ubackup -h10.0.99.76 -pEng123Form -Ddb_backups -e' #Mostra a grade com os Campos das tabelas.

#É necessário instalar a chave publica no arquivo ~/.ssh/authorized_keys da Origem
varChave="$HOME/.ssh/chaveprivada"

#Verificacao das Variaveis
ORI=$($varMSQLC "Select COD From Origem")
DES=$($varMSQLC "Select COD From Destino")

function CadOrigDest(){
		tput clear
		if [ $1 = "Origem" ]; then
			##Afixação dos campos##
			CenterTitle "Cadastro de Dados para a tabela $1"
			tput cup 5 2
			echo -e "Nome para ponto de montagem em $1 ex.: AD : \c"
			tput cup 6 2
			echo -e "Nome do compartilhamento. ex.: dados: \c"
			tput cup 7 2
			echo -e "IP da maquina. ex.: 10.0.99.17 : \c"
			tput cup 8 2
			echo -e "Usuario com acesso : \c"
			tput cup 9 2
			echo -e "Senha do usuário com acesso acima : \c"
					
			##Captação de Dados##
			tput cup 5 2
			echo -e "Nome para ponto de montagem em $1 ex.: AD : \c"
			read R_Nome
			tput cup 6 2
			echo -e "Nome do compartilhamento. ex.: dados: \c"
			read R_Local
			tput cup 7 2
			echo -e "IP da maquina. ex.: 10.0.99.17 : \c"
			read R_IP
			tput cup 8 2
			echo -e "Usuario com acesso : \c"
			read R_USER
			tput cup 9 2
			echo -e "Senha do usuário com acesso acima : \c"
			read R_PASSWD
			tput cup 11 5
			echo -e "Iniciando testes de Conexão..."
			tput cup 12 5
			echo -e "Verificando tamanho total do disco e armazenando a informação"
			if $(df -h | grep -q /mnt/$R_Nome); then
				umount /mnt/$R_Nome
				rm -R /mnt/$R_Nome
			fi
			mkdir -p /mnt/$R_Nome
			mount.cifs //$R_IP/$R_Local /mnt/$R_Nome -o user=$R_USER,pass=$R_PASSWD
			R_ESPACO=`df /mnt/$R_Nome | tr -s ' ' | cut -d' ' -f2 | sed -n '/$*.[0-9]/p'` #Verificar o tamanho do HDD
			umount /mnt/$R_Nome
			rm -R /mnt/$R_Nome
			tput cup 15 5
			echo "Espaço em Kb: $R_ESPACO"
			tput cup 16 5
			echo "Gravando informações no Banco de Dados"
			$varMSQLC "INSERT INTO $1 (Nome, Share, IP, Espaco_Total, Usuario, Senha) VALUES ('$R_Nome', '$R_Local', '$R_IP', '$R_ESPACO', '$R_USER', '$R_PASSWD')"
			sleep 2
			tput cup 17 5
			echo "Dados Gravados com sucesso"
			tput cup 18 5
			echo "Exibindo linha gravada"
			$varMSQLC "SELECT * FROM $1 WHERE Nome='$R_Nome'"
			tput cup 21 5
			echo -e "Deseja Cadastrar um novo Registro para $1? S/N \c"
			read R_CAD
			if [ "$R_CAD" = "S" ]; then
				CadOrigDest $1
			fi

		elif [ $1 = "Destino" ]; then
			##Afixação dos campos##
			CenterTitle "Cadastro de Dados para a tabela $1"
			tput cup 5 2
			echo -e "Nome para ponto de montagem em $1 ex.: DADOSAD : \c"
			tput cup 6 2
			echo -e "Nome da pasta de destino. ex.: dadosad: \c"
					
			##Captação de Dados##
			tput cup 5 2
			echo -e "Nome para ponto de montagem em $1 ex.: DADOSAD : \c"
			read R_Nome
			tput cup 6 2
			echo -e "Nome da pasta de destino. ex.: dadosad: \c"
			read R_Local
			tput cup 8 5
			echo -e "Verificando tamanho total do disco e armazenando a informação"
				R_ESPACO=`df /$R_Local | tr -s ' ' | cut -d' ' -f2 | sed -n '/$*.[0-9]/p'` #Verificar o tamanho do HDD
			tput cup 10 5
			echo "Espaço em Kb: $R_ESPACO"
			tput cup 11 5
			echo "Gravando informações no Banco de Dados"
			$varMSQLC "INSERT INTO $1 (Nome, Local, Espaco_Total) VALUES ('$R_Nome', '$R_Local', '$R_ESPACO')"
			sleep 2
			tput cup 12 5
			echo "Dados Gravados com sucesso"
			tput cup 14 5
			echo "Exibindo linha gravada"
			tput cup 15 5
			$varMSQLC "SELECT * FROM $1 WHERE Nome='$R_Nome'"
			tput cup 21 5
			echo -e "Deseja Cadastrar um novo Registro para $1? S/N \c"
			read R_CAD
			#tput cup 21 5
			if [ "$R_CAD" = "S" ]; then
				CadOrigDest $1
			fi
		fi
}

function CadDestinatarios(){
	
		#TEMDADOS=`$varMSQLC 'select Destinatarios.COD from Destinatarios'`

		##Afixação dos campos##
		CenterTitle "Cadastro de Dados para os Destinatários de Relatórios de Backup"
		tput cup 5 2
		echo -e "Digite o Nome do Destinatario. ex.: Yudy : \c"
		tput cup 6 2
		echo -e "Digite o Email do Destinatario. ex.: yudy@kingit.com.br : \c"
				
		##Captação de Dados##
		tput cup 5 2
		echo -e "Digite o Nome do Destinatario. ex.: Yudy : \c"
		read R_Nome
		tput cup 6 2
		echo -e "Digite o Email do Destinatario. ex.: yudy@kingit.com.br : \c"
		read R_Email
		tput cup 7 5
		echo "Gravando informações no Banco de Dados"
		$varMSQLC "INSERT INTO Destinatarios (Nome, Email) VALUES ('$R_Nome', '$R_Email')"
		sleep 2
		tput cup 8 5
		echo "Dados Gravados com sucesso"
		tput cup 9 5
		echo -e "Deseja cadastrar um novo destinatário? S/N \c"
		read R_CAD
		if [ "$R_CAD" = "S" ]; then
			CadDestinatarios
		fi
}

function LinkOrigDest () {
		##Afixação dos campos##
		tput clear
		CenterTitle "Link entre Origem e Destino"
		echo "
		"
		ORIGENS=($($varMSQLC "Select Nome From Origem"))
		DESTINOS=($($varMSQLC "Select Nome From Destino"))
		
		PS3="Selecione a Origem: "

		#echo ${varOpcoes[@]} #Mostra os itens
		#echo ${!varOpcoes[@]} #Mostra as quantidades
		#echo ${#varOpcoes[@]} #Mostra o Total
		select listORI in ${ORIGENS[@]} "Sair"
		do
			if [ "$listORI" = "Sair" ]; then
				echo "Você selecionou $listORI"; echo "flw vlw"; sleep 3; break;
				break
			elif [ -n "$listORI" ]; then
				echo "Você selecinou $lista"
				echo ""
				SELECT_O=$listORI
				#Começando segunda lista
				PS3="Selecione o Destino: "
				select listDES in ${DESTINOS[@]} "Sair"; do
					if [ "$listDES" = "Sair" ]; then
						echo "Você selecionou $listDES"; echo "flw vlw"; sleep 3; break;
						break
					elif [ -n "$listDES" ]; then
						echo "Você selecinou $listDES"
						echo ""
						SELECT_D=$listDES
						echo "Vamos linkar a Origem: $SELECT_O com o Destino: $SELECT_D, confirma? S/N"
						read R_CONF
						if [ $R_CONF = "S" ]; then
							C_ORIGEM=$($varMSQLC "Select COD From Origem Where Nome='$SELECT_O'")
							C_DESTINO=$($varMSQLC "Select COD From Destino Where Nome='$SELECT_D'")
							$varMSQLC "INSERT INTO LinkBackup (COD_ORIGEM, COD_DESTINO) VALUES ('$C_ORIGEM', '$C_DESTINO')"
							echo "Link executado com sucesso"
							echo "Exibindo tabela gravada"
							$varMSQLC "Select * From LinkBackup"
							echo "Voltando para o Menu Principal em 5 segundos"
							sleep 5
							ColetaDados
						else
							echo "Selecione uma opcao valida Maldito"; sleep 3;
							continue
						fi
					fi
				done
				
			else
				echo "Selecione uma opcao valida Maldito"; sleep 3;
				continue
			fi
			
		done
		
}

function ExibeCadastros () {
	tput clear 
	CenterTitle "Exibindo Cadastros do Banco de Dados"
	echo "
	Dados Origem
	"
	if [ ! -z "$ORI" ]; then
		$varMSQLCT "Select COD, Nome, Share From Origem"
	else
		echo "Dados da Origem ainda não cadastrados"
	fi
	echo "
	Dados Destino
	"
	if [ ! -z "$DES" ]; then
		$varMSQLCT "Select COD, Nome, Local From Destino"
	else
		echo "Dados do Destino ainda não cadastrados"
	fi	

}

function ColetaDados(){
#Capitação dos dados iniciais para cadastro na base de dados.
clear
#Opção desejada
echo "Por favor digite a opção que deseja"
echo ""
echo "1. Cadastrar Origens"
echo "2. Cadastrar Destinos"
echo "3. Cadastrar Destinatários"
echo "4. Exibe Cadastros"

if [ ! -z "$ORI" ] && [ ! -z "$DES" ]; then
echo "5. Linkar Origem x Destino"
fi
#echo "7. Troca de senha por lista"
echo "9. Sair"
echo ""
read R_TMP

case $R_TMP in
	1) CadOrigDest "Origem";;
	2) CadOrigDest "Destino" ;;
	3) CadDestinatarios ;;
	4) ExibeCadastros ;;
	5) LinkOrigDest ;;
	#7) TrocaSenhaLista ;;
	9) echo "Valew Falow" ; exit;;
	*) echo "Por favor escolha uma opção valida. Voltando para o Menu Principal."; sleep 3 ; ColetaDados ;;
esac
}

ColetaDados
#montarCompartilhamento $1 $2 $3
