#!/bin/bash
##################################################
# Name: bk.sh
# Description: Backup on mongodb
# Script Maintainer: Rafael
#
# Versão: 1.5
# Last Updated: November 30th 2015
##################################################
###### 			Backup log files		   ####### 
# 
#Conection string with mongodb server and database


BASEM="10.0.99.77/kingit" #Database
BANCOM="backup" #Collection
#MCon="mongo 10.0.99.77/test --eval"
: << 'DESCR'
Acessar MongoDB Remoto
vim /etc/mongod.conf

# /etc/mongod.conf

# Listen to local, LAN and Public interfaces.
bind_ip = 127.0.0.1,192.168.161.100,45.56.65.100
DESCR

#Dados que precisam ser preenchidos para a realização do Backup
#Como pré requisito será necessário ter os compartilhamentos já montados
		BKP_NAME="Arquivos_de_Producao"
		ORIGEM="/mnt/rafa/"
		DESTINO="/fluigbkp"
		QTDE_BKPSD=14


#Collected Data

function backup (){
		tput clear
		###################################
		T_DIA=`date +%F`
		T_HORA=`date +%H:%M`
		LOG="/tmp/log_"$BKP_NAME"_$T_DIA~$T_HORA.log"
		DATA_ANTES="$T_DIA~$T_HORA" #Mostra a data e a hora em que foi realizado o backup para envio do assunto do email
		
		echo "fazendo o backup da parada"
		rsync -bhaviAE --compress-level=9 --stats --delete-after --backup-dir="$DESTINO/bkp_diff/$T_DIA/bkp_$T_HORA/" --suffix=.old "$ORIGEM" "$DESTINO/incremental/" >> $LOG
		#sleep 10
		
		
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


		
		mongo $BASEM --eval 'db.'$BANCOM'.insert({"BkpName": "'$BKP_NAME'", "Active": "true", "Report": {"StartDate": "'$DATA_ANTES'", "EndDate": "'$DATA_DEPOIS'", "NumRegFiles": "'$T_Num_Files'", "NumDir": "'$T_Num_Dir'", "NewDir": "'$T_New_Dir'", "NewRegFiles": "'$T_Num_New_Files'", "NumDelFiles": "'$T_Num_Del_Files'", "NumDelDir": "'$T_Del_Dir'", "CopyFiles": "'$T_Num_Copy_Files'", "TotalTransf": "'$T_Total_Transf'", "TotalSize": "'$TOT_Size'"}})'
		#, "Files": ["Nenhum Arquivo"], "DelFiles": ["Nenhum Deletado"]
		echo "Separando arquivos deletados e copiados"
		
		SAVEIFS=$IFS
		IFS=$(echo -en "\n\b")
		echo "Verificando se existem arquivos novos ou atualizados"
		for f in $(cat "$LOG" | sed -n '/^>f/p' | sed 's/^>...........//'); do 
			mongo $BASEM --eval 'db.'$BANCOM'.update({"Report.StartDate": "'$DATA_ANTES'"}, {$push: {"Report.Files": "'$f'"}},{upsert: true})'
		done
		if [ -z "$(cat "$LOG" | sed -n '/^>f/p' | sed 's/^>...........//')" ];then
			echo "Nenhum arquivo novo"
			mongo $BASEM --eval 'db.'$BANCOM'.update({"Report.StartDate": "'$DATA_ANTES'"}, {$set: {"Report.Files": ["Nenhum Arquivo"]}})'
		fi
		
		echo "Verificando se existem arquivos deletados"
		
		for fd in $(cat "$LOG" | sed -n '/^*deleting/p' | sed 's/*deleting...//'); do 			
			mongo $BASEM --eval 'db.'$BANCOM'.update({"Report.StartDate": "'$DATA_ANTES'"}, {$push: {"Report.DelFiles": "'$fd'"}},{upsert: true})'
		done
		if [ -z "$(cat "$LOG" | sed -n '/^*deleting/p' | sed 's/*deleting...//')" ]; then
			echo "Nenhum arquivo Deletado"
			mongo $BASEM --eval 'db.'$BANCOM'.update({"Report.StartDate": "'$DATA_ANTES'"}, {$set: {"Report.DelFiles": ["Nenhum Deletado"]}})'
		fi
		echo "Salvando a data e hora de finalização do backup"
		IFS=$SAVEIFS
		DATA_DEPOIS=`date +%F~%H:%M` #Mostra a data e a hora em que foi realizado o backup para envio do assunto do email
		mongo $BASEM --eval 'db.'$BANCOM'.update({"Report.StartDate": "'$DATA_ANTES'"}, {$set: {"Report.EndDate": "'$DATA_DEPOIS'"}})'

		sleep 5
		echo "Parabéns você leu tudo"
		#Remover o arquivo de Log Temporário
		#rm $LOG
}

: << 'SCHEMA'

db.backup.insert({
"BkpName": "'$BKP_NAME'",
"Active": "true",
"Report":{
"StartDate": "'$DATA_ANTES'", 
"EndDate": "'$DATA_DEPOIS'", 
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
"DelFiles": ["Nenhum Deletado"]}})

SCHEMA
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
echo "From: backup.servidor@euquefiz.com.br" >> $DADOSEMAIL
echo "Subject: Backup Teste" >> $DADOSEMAIL
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

Dados sobre o backup desta semana de $(Relatorio | sed -n "/StartDate/p" | sed -e ''$QTDE_BKPSD'!d' | sed 's/\t\t"'StartDate'" : "//;s/".*$//') a $(Relatorio | sed -n "/StartDate/p" | sed -e '1!d' | sed 's/\t\t"'StartDate'" : "//;s/".*$//') : <p>

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

backup
#echo "Resultado da parada"
#echo $(Relatorio | sed -n '/NumRegFiles/p' | sed -e '$!d' | sed 's/\t\t"NumRegFiles" : "//;s/",//')
#echo $(Relatorio | sed -n '/TotalTransf/p' | sed -e '1,7!d' | sed 's/\t\t"TotalTransf" : "//;s/",//')
#Relatorio | sed -n '/CopyFiles/p' | sed -e '1!d' | sed 's/\t\t"CopyFiles" : "//;s/",//'
#echo $(df -h | grep $(echo $ORIGEM | sed 's_/$__') | tr -s ' ' | cut -d" " -f4)
#printf "%0.1f\n" $tot
#echo $tot
MontaEmail
#Relatorio
#echo $(calculatotal CopyFiles)
#echo $(Relatorio | sed -n '/StartDate/p' | sed -e '1!d' | sed 's/\t"StartDate" : "//;s/",//')
