#!/bin/bash
##################################################
# Name: bk.sh
# Description: Backup on mongodb
# Script Maintainer: Rafael
#
# Versão: 1.5
# Last Updated: April 3th 2016
##################################################
###### 			Backup log files		   ####### 
# 

#$ vim /etc/mongod.conf

# /etc/mongod.conf

# Listen to local and LAN interfaces.
#bind_ip = 127.0.0.1,192.168.161.100
: <<'Features'
- Use the function to read the log file and save on the database after have homologed it
DRY Code
Features


: <<'FUNCTIONS'
- The program need to run from destination computer.

- Verify if there are shared folders in the origin computer

- Ask for username and password to access those shared folders
check if the user want to save the information inside database

- 


Create default username and password to access the shares

New desired features:

- Line commands with dinamic backup
ex. bk.sh MAURO-OBRA576 /mnt/obra/ /bkpobras

It's necessary that mount points are ready to go
-------------------------------------------------

- Count all the backups made and show them on an email sent to users.

- Menu

- File Server - Local
				Remote
				
- XVA - Virtualização

- Backup Desktop- Autocompletar
				- APP data
				- Perfil
				- Programas da Receita
				- Email - PST, OST, DAT, NK2
				
- Exibir Unidades Montadas - DF -h
- Opção para Montar uma nova unidade ou Desktop da Rede



[ $# -eq 0 ] && { echo -e "\nUsage: $0 [NetworkAddress] [Share] [Destination] [Name]\nExample: $0 10.0.99.17 dados dadosad FILESRV_MATRIZ\n"; exit 1; }
	
[ $# -lt 4 ] && { echo -e "\nUsage: $0 [NetworkAddress] [Share] [Destination] [Name]\nExample: $0 10.0.99.17 dados dadosad FILESRV_MATRIZ\n"; exit 2; }

_IP="$1"
_SHARE="$2"
_DEST="$3"
_NOME="$4"

echo "Montando compartilhamento"


mkdir -p /mnt/$_NOME
mount.cifs //$_IP/$_SHARE /mnt/$_NOME -o user,credentials=/root/.cifs - # é necessário criar o arquivo.cifs com as credenciais do usuário com permissão aos computadores que serão backupeados.
df -h

FUNCTIONS

#Conection string with mongodb server and database


#BASEM="10.0.99.77/kingit" #Database
#_BASEM="kingit.ddnsking.com/kingit" #Database
_BASEM="192.168.0.50/test" #Database
_COLLECTIONM="backup" #Collection
_Destination="/backups"
#MCon="mongo 10.0.99.77/test --eval"
: << 'DESCR'
Acessar MongoDB Remoto
vim /etc/mongod.conf

# /etc/mongod.conf

# Listen to local, LAN and Public interfaces.
bind_ip = 127.0.0.1,192.168.161.100,45.56.65.100


#Dados que precisam ser preenchidos para a realização do Backup
#Como pré requisito será necessário ter os compartilhamentos já montados
		BKP_NAME="$_NOME"
		ORIGEM="/mnt/$_NOME/"
		DESTINO="/$_DEST"
		QTDE_BKPSD=14

DESCR
#Collected Data

function backup (){ #To use backup NameBkp Source $_Destination#/backups
		SAVEIFS=$IFS ##Ajustando problemas de espaços entre nomes
		IFS=$(echo -en "\n\b")
		_BKP_NAME=$1
		_BKP_Source=$2
		_BKP_Destination=$3
		tput clear
		###################################
		[[ ! -d "$_BKP_Destination/$_BKP_NAME" ]] && { mkdir -p "$_BKP_Destination/$_BKP_NAME/logs"; }
		local T_DAY=`date +%F`
		local T_HOUR=`date +%H:%M:%S`
		_LOG="$_BKP_Destination/$_BKP_NAME/logs/$_BKP_NAME~$T_DAY~$T_HOUR.log"
		_DATE_BEFORE="$T_DAY~$T_HOUR" #Mostra a data e a hora em que foi realizado o backup para envio do assunto do email
		
		
		echo "Doing the backup process"
		rsync -bhaviAE --compress-level=9 --stats --delete-after --backup-dir="$_BKP_Destination/$_BKP_NAME/bkpdiff/$T_DAY/$T_HOUR/" --suffix=.old "$_BKP_Source" "$_BKP_Destination/$_BKP_NAME/incremental/" >> $_LOG
		#sleep 10
		echo "Backup Process done sucessfully"
		IFS=$SAVEIFS ##Fim do Ajuste entre espacos
}

function captaLog(){ # captaLog $_LOG $_DATE_BEFORE $_BASEM $_COLLECTIONM
		SAVEIFS=$IFS ##Ajustando problemas de espaços entre nomes
		IFS=$(echo -en "\n\b")
		local LOG=$1
		local DATE_BEFORE=$2
		local BASEM=$3
		local COLLECTIONM=$4
		_BKP_NAME=$5
		_BKP_Source=$6
		echo "Captacao dos dados e separacao das informacoes do log."

		Fields=("Number of files" "Number of created files" "Number of deleted files")
		for i in ${!Fields[@]};do
				varF=0
				varD=0
				#echo "${Fields[$i]}"
				if [ $(cat $LOG | grep "${Fields[$i]}" | cut -d: -f2 | sed 's/ //;s/ .*$//' | sed 's/,//') -ne "0" ];then
					varF=$(cat $LOG | grep "${Fields[$i]}" | cut -d: -f3 | sed 's/ //;s/ .*$//' | sed 's/,//g;s/)//')
					if $(cat $LOG | grep "${Fields[$i]}" | grep -q dir); then
						varD=$(cat $LOG | grep "${Fields[$i]}" | cut -d: -f4 | sed 's/ //;s/ .*$//' | sed 's/,//;s/)//')
					else					
						varD="0"
					fi
				else
					varF="0"
				fi
			case ${Fields[$i]} in
				"Number of files" )
					T_Num_Files=$varF
					T_Num_Dir=$varD
					;;
				"Number of created files" )
					T_Num_New_Files=$varF
					T_New_Dir=$varD
					;;
				"Number of deleted files" )
					T_Num_Del_Files=$varF
					T_Del_Dir=$varD
					;;
			esac	
		done
			
		T_Num_Copy_Files=$(cat $LOG | grep "Number of regular files transferred" | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/,//')
		
		
		TMP_TOT_Size=$(cat $LOG | grep "Total file size" | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/ bytes//')
		if $(echo $TMP_TOT_Size | grep -q K); then
			TOT_Size=$(echo "$TMP_TOT_Size" | sed 's/[a-Z]$//')
		elif $(echo $TMP_TOT_Size | grep -q M); then
			Vlr=$(echo "$TMP_TOT_Size" | sed 's/[a-Z]$//')
			TOT_Size=$(echo "$Vlr * 1024" | bc)
		elif $(echo $TMP_TOT_Size | grep -q G); then
			Vlr=$(echo "$TMP_TOT_Size" | sed 's/[a-Z]$//')
			TOT_Size=$(echo "($Vlr * 1024)* 1024" | bc)
		elif $(echo $TMP_TOT_Size | grep -q T); then
			Vlr=$(echo "$TMP_TOT_Size" | sed 's/[a-Z]$//')
			TOT_Size=$(echo "(($Vlr * 1024)* 1024)* 1024" | bc)
		else
			TOT_Size=$TMP_TOT_Size
		fi
		TMP_Total_Transf=$(cat $LOG | grep "Literal data" | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/ bytes//')
		echo "Ajustando Tamanho do backup para exibir em Kbytes"
		if $(echo $TMP_Total_Transf | grep -q K); then
			T_Total_Transf=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
		elif $(echo $TMP_Total_Transf | grep -q M); then
			Vlr=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
			T_Total_Transf=$(echo "$Vlr * 1024" | bc)
		elif $(echo $TMP_Total_Transf | grep -q G); then
			Vlr=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
			T_Total_Transf=$(echo "($Vlr * 1024)* 1024" | bc)
		elif $(echo $TMP_Total_Transf | grep -q T); then
			Vlr=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
			T_Total_Transf=$(echo "(($Vlr * 1024)* 1024)* 1024" | bc)
		else
			T_Total_Transf=$TMP_Total_Transf
		fi
		
		echo "Gravando na Base"
		#Verifying if the data alread exists
		#mongo kingit.ddnsking.com/kingit --eval 'db.backup.find({}, {_id: 0, BkpName: 1}).pretty().shellPrint()'
		if $(mongo $BASEM --eval 'db.'$COLLECTIONM'.find({}, {"_id": 0, "BkpName": 1}).pretty().shellPrint()' | grep -q $_BKP_NAME); then
			echo "Data Exists"
			mongo $BASEM --eval 'db.'$COLLECTIONM'.update({"BkpName": "'$_BKP_NAME'", "Source": "'$_BKP_Source'"}, {$inc: { "Count": 1 }})'
			local _LogID=$_BKP_NAME-$(mongo $BASEM --eval 'db.'$COLLECTIONM'.find({"BkpName": "'$_BKP_NAME'"}, {"_id": 0, "Count": 1}).pretty().shellPrint()' | grep Count | cut -d: -f2 | sed 's/ //g;s/}//')
			echo "Including data to Log"
			mongo $BASEM --eval 'db.'$COLLECTIONM'.update({"BkpName": "'$_BKP_NAME'", "Source": "'$_BKP_Source'"}, {$push: {"Report": {"Active": "true", "StartDate": "'$DATE_BEFORE'", "EndDate": "'$DATE_AFTER'", "LogID": "'$_LogID'"}}})'
			mongo $BASEM --eval 'db.log.insert({"_id": "'$_LogID'", "Log":{"NumRegFiles": "'$T_Num_Files'", "NumDir": "'$T_Num_Dir'",	"NewRegFiles": "'$T_Num_New_Files'", "NewDir": "'$T_New_Dir'", "NumDelFiles": "'$T_Num_Del_Files'", "NumDelDir": "'$T_Del_Dir'", "CopyFiles": "'$T_Num_Copy_Files'", "TotalTransf": "'$T_Total_Transf'", "TotalSize": "'$TOT_Size'", "Files": ["Nenhum Arquivo"], "DelFiles": ["Nenhum Deletado"]}})'
		else
			#Fist Time Backup
			echo "FirstBackup"
			mongo $BASEM --eval 'db.'$COLLECTIONM'.insert({"BkpName": "'$_BKP_NAME'","Source": "'$_BKP_Source'", "Count": 1, "Report": [{"Active": "true", "StartDate": "'$DATE_BEFORE'", "EndDate": "'$DATE_AFTER'", "LogID": "'$_BKP_NAME-1'"}]})'
			mongo $BASEM --eval 'db.log.insert({"_id": "'$_BKP_NAME-1'", "Log":{"NumRegFiles": "'$T_Num_Files'", "NumDir": "'$T_Num_Dir'",	"NewRegFiles": "'$T_Num_New_Files'", "NewDir": "'$T_New_Dir'", "NumDelFiles": "'$T_Num_Del_Files'", "NumDelDir": "'$T_Del_Dir'", "CopyFiles": "'$T_Num_Copy_Files'", "TotalTransf": "'$T_Total_Transf'", "TotalSize": "'$TOT_Size'", "Files": ["Nenhum Arquivo"], "DelFiles": ["Nenhum Deletado"]}})'
		fi
		sleep 10
		#, "Files": ["Nenhum Arquivo"], "DelFiles": ["Nenhum Deletado"]
		echo "Separando arquivos deletados e copiados"
		
		
		echo "Verificando se existem arquivos novos ou atualizados"
		for f in $(cat "$LOG" | sed -n '/^>f/p' | sed 's/^>...........//'); do 
			mongo $BASEM --eval 'db.log.update({"_id": "'$_LogID'"}, {$push: {"Log.Files": "'$f'"}},{upsert: true})'
			mongo $BASEM --eval 'db.log.update({"_id": "'$_LogID'"}, {$pull: {"Log.Files": "Nenhum Arquivo"}})'
		done
		if [ -z "$(cat "$LOG" | sed -n '/^>f/p' | sed 's/^>...........//')" ];then
			echo "Nenhum arquivo novo"
			mongo $BASEM --eval 'db.log.update({"_id": "'$_LogID'"}, {$set: {"Log.Files": ["Nenhum Arquivo"]}})'
		fi
		
		echo "Verificando se existem arquivos deletados"
		
		for fd in $(cat "$LOG" | sed -n '/^*deleting/p' | sed 's/*deleting...//'); do 			
			mongo $BASEM --eval 'db.log.update({"_id": "'$_LogID'"}, {$push: {"Log.DelFiles": "'$fd'"}},{upsert: true})'
			mongo $BASEM --eval 'db.log.update({"_id": "'$_LogID'"}, {$pull: {"Log.DelFiles": "Nenhum Deletado"}})'
		done
		if [ -z "$(cat "$LOG" | sed -n '/^*deleting/p' | sed 's/*deleting...//')" ]; then
			echo "Nenhum arquivo Deletado"
			mongo $BASEM --eval 'db.log.update({"_id": "'$_LogID'"}, {$set: {"Log.DelFiles": ["Nenhum Deletado"]}})'
		fi
		echo "Salvando a data e hora de finalização do backup"
		IFS=$SAVEIFS ##Fim do Ajuste entre espacos
		DATE_AFTER=`date +%F~%H:%M` #Mostra a data e a hora em que foi realizado o backup para envio do assunto do email
		mongo $BASEM --eval 'db.'$COLLECTIONM'.update({"Report.StartDate": "'$DATE_BEFORE'"}, {$set: {"Report.$.EndDate": "'$DATE_AFTER'"}})'

		sleep 5
		echo "Parabéns você leu tudo"
		#Remover o arquivo de Log Temporário
		#rm $LOG
}



: << 'SCHEMA'

db.backup.insert({
	"BkpName": "'$BKP_NAME'",
	"Source": "'$_BKP_Source'",
	"Count": 0,
	"Report":[{
			"Active": "true",
			"StartDate": "'$DATA_ANTES'", 
			"EndDate": "'$DATA_DEPOIS'", 
			"LogID": "'$_LogID'",
			}]
	}
})

$_LogID é composto do nome do cliente $BKP_NAME e o Count de backup

db.log.insert({
		"_id": $_LogID
		"Log":{
				"NumRegFiles": "'$T_Num_Files'", 
				"NumDir": "'$T_Num_Dir'",
				"NewRegFiles": "'$T_Num_New_Files'",
				"NewDir": "'$T_New_Dir'",
				"NumDelFiles": "'$T_Num_Del_Files'",
				"NumDelDir": "'$T_Del_Dir'", 
				"CopyFiles": "'$T_Num_Copy_Files'", 
				"TotalTransf": "'$T_Total_Transf'", 
				"TotalSize": "'$TOT_Size'",
				"Files": ["Nenhum Arquivo"], 
				"DelFiles": ["Nenhum Deletado"]
			}
})
SCHEMA


#backup "Rafa" "/media/rafael/hdd1tera/KingitCloud_/Padrao" "/media/rafael/hdd1tera/backups"

[ $# -lt 3 ] && { echo -e "\nUsage: $0 [BKPNAME] [Source] [Destination]\nExample: $0 MOGI /mnt/dados /backup"; exit 1; }
	
#[ $# -lt 4 ] && { echo -e "\nUsage: $0 [NetworkAddress] [Share] [Destination] [Name]\nExample: $0 10.0.99.17 dados dadosad FILESRV_MATRIZ\n"; exit 2; }
SAVEIFS=$IFS ##Ajustando problemas de espaços entre nomes
IFS=$(echo -en "\n\b")
	backup $1 $2 $3
	echo "
	We Finish the backup process for $1
	"
	sleep 3

	captaLog $_LOG $_DATE_BEFORE $_BASEM  $_COLLECTIONM  $_BKP_NAME $_BKP_Source
IFS=$SAVEIFS ##Fim do Ajuste entre espacos

##################################################
# Sistema de Relatórios iniciando aqui
#
function Relatorio () {
	##Recuperar todos os dados para geração dos relatórios
	#echo "Relatório por email"
	mongo $BASEM --eval 'printjson(db.'$BANCOM'.find({} ,{_id: 0, "BkpName": 1, "Active": 1, "Report.StartDate": 1, "Report.EndDate": 1, "Report.NumRegFiles": 1, "Report.NumDir": 1, "Report.NewRegFiles": 1, "Report.NewDir": 1, "Report.NumDelFiles": 1, "Report.NumDelDir": 1, "Report.CopyFiles": 1, "Report.TotalTransf": 1, "Report.TotalSize": 1}).sort({"Report.StartDate":-1}).pretty().shellPrint())'	
	
}

function calculatotal () {
T_New=($(Relatorio | sed -n "/$1/p" | sed -e '1,'$QTDE_BKPSD'!d' | sed 's/\t\t"'$1'" : "//;s/".*$//'))
T_Soma=0
for i in ${T_New[@]}; do
	T_Soma=`echo $T_Soma + $i | bc`
done
echo $T_Soma
}

function MontaEmail (){
DADOSEMAIL=/tmp/email.tmp
#DESTINATARIOS="rafael@kingit.com.br, yudy@kingit.com.br"
DESTINATARIOS="rafael@kingit.com.br"


#Configuracao para email
echo "To: $DESTINATARIOS" >> $DADOSEMAIL
echo "From: monitoramento@kingit.com.br" >> $DADOSEMAIL
echo "Subject: Backup $_NOME" >> $DADOSEMAIL
echo "MIME-Version: 1.0" >> $DADOSEMAIL
echo "Content-Type: text/html; charset='UTF-8'" >> $DADOSEMAIL
#Fim da configuracao de email.
#------------------------------
#Corpo do Email
TOT_Transf=0
TOT_Transf=$(echo "$(calculatotal TotalTransf) / 1024" | bc)
TOT_Origem=0
TOT_Origem=$(echo "$(Relatorio | sed -n '/TotalSize/p' | sed -e '1!d' | sed 's/\t\t"TotalSize" : "//;s/",//') / 1024" | bc)
echo -e "
$(Relatorio | sed -n '/BkpName/p' | sed -e '1!d' | sed 's/\t"BkpName" : "//;s/",//') - com $(Relatorio | sed -n '/CopyFiles/p' | sed -e '1!d' | sed 's/\t\t"CopyFiles" : "//;s/",//') Arquivos Copiados na ultima Vez</p>

Algumas informações sobre $(Relatorio | sed -n '/BkpName/p' | sed -e '1!d' | sed 's/\t"BkpName" : "//;s/",//'):<p>

$(Relatorio | sed -n '/NumRegFiles/p' | sed -e '1!d' | sed 's/\t\t"NumRegFiles" : "//;s/",//') Arquivos totais<br />
$(Relatorio | sed -n '/NumDir/p' | sed -e '1!d' | sed 's/\t\t"NumDir" : "//;s/",//') Diretorios<br />
$TOT_Origem Mega Bytes de Volume total<br />
$(df -h | grep $(echo $ORIGEM | sed 's_/$__') | tr -s ' ' | cut -d" " -f4) Espaço livre <p>

Dados sobre os ultimos $QTDE_BKPSD backups realizados entre $(Relatorio | sed -n "/StartDate/p" | sed -e ''$QTDE_BKPSD'!d' | sed 's/\t\t"'StartDate'" : "//;s/".*$//') e $(Relatorio | sed -n "/StartDate/p" | sed -e '1!d' | sed 's/\t\t"'StartDate'" : "//;s/".*$//') : <p>

$(calculatotal NewRegFiles) Arquivos novos criados<br />
$(calculatotal NewDir) Diretórios novos criados<br />
$(calculatotal NumDelFiles) Arquivos Deletados<br />
$(calculatotal NumDelDir) Diretórios Deletados<br />
$TOT_Transf Mega Bytes de dados transferidos<br />
$(df -h | grep $(echo $DESTINO | sed 's_/$__') | tr -s ' ' | cut -d" " -f4) Espaço Livre<p>

-------------------------------------------------------------<p />
" >> $DADOSEMAIL
##Envio do email para os destinatarios
ssmtp $DESTINATARIOS < $DADOSEMAIL	
#echo $(cat $DADOSEMAIL)
echo "E-mail enviado com sucesso"
rm $DADOSEMAIL
}

function MostraMenu() {
	R_Select=$(zenity --list --title="Selecione o tipo de backup" \
	--column="Tipo" --column="Descrição" \
	FileServer "Backup da Rede" \
	XVA Virtualizações \
	Desktop Desmobilização)
	
	zenity --info --title="Unidades Montadas" --text="$(df -h | grep media | tr -s ' ')"
	
	case $R_Select in
		FileServer) zenity --info --title="Unidades Montadas" --text="$(df -h | grep media | tr -s ' ')"
		;;
		XVA) echo "Você selecionou $R_Select"
		;;
		Desktop) echo "Você selecionou $R_Select"
		;;
	esac
}

function MenuShell () {
	echo "Menu de Opções de Backup"
	echo "
			Exibindo Unidades Montadas
	"
	df -h | grep -v tmpfs | grep -v udev | tr -s ' ' | cut -d" " -f 6 | sed '1,2d' 
	
}

function Progress () {
# Create an array of all files in /etc and /bin directory
DIRS=($ORIGEM*)
 
# Destination directory
DEST="$DESTINO"
 
# Create $DEST if does not exits
#[ ! -d $DEST ] && mkdir -p $DEST
 
#
# Show a progress bar
# ---------------------------------
# Redirect dialog commands input using substitution
#
dialog --title "Copy file" --gauge "Copying file..." 10 175 < <(
   # Get total number of files in array
   n=${#DIRS[*]}; 
 
   # set counter - it will increase every-time a file is copied to $DEST
   i=0
 
   #
   # Start the for loop 
   #
   # read each file from $DIRS array 
   # $f has filename 
   for f in "${DIRS[@]}"
   do
      # calculate progress
      PCT=$(( 100*(++i)/n ))
 
      # update dialog box 
cat <<EOF
XXX
$PCT
Copying file "$f"...
XXX
EOF
  # copy file $f to $DEST 
  rsync -bhaviAE --compress-level=9 --stats --delete-after --backup-dir="/bkp_diff/$T_DIA/bkp_$T_HORA/" --suffix=.old "$f" "$DESTINO/incremental/" >> $LOG
   done
)
 
# just delete $DEST directory
#/bin/rm -rf $DEST	
	
	
}



#echo "Resultado da parada"
#echo $(Relatorio | sed -n '/NumRegFiles/p' | sed -e '$!d' | sed 's/\t\t"NumRegFiles" : "//;s/",//')
#echo $(Relatorio | sed -n '/TotalTransf/p' | sed -e '1,7!d' | sed 's/\t\t"TotalTransf" : "//;s/",//')
#Relatorio | sed -n '/CopyFiles/p' | sed -e '1!d' | sed 's/\t\t"CopyFiles" : "//;s/",//'
#echo $(df -h | grep $(echo $ORIGEM | sed 's_/$__') | tr -s ' ' | cut -d" " -f4)
#printf "%0.1f\n" $tot
#echo $tot
: <<'TESTE'
backup
MontaEmail

TESTE

#backup
#MontaEmail

#umount /mnt/$_NOME
#Relatorio
#echo $(calculatotal CopyFiles)
#echo $(Relatorio | sed -n '/StartDate/p' | sed -e '1!d' | sed 's/\t"StartDate" : "//;s/",//')
#MenuShell
