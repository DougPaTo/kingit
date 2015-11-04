#!/bin/bash
##################################################
# Name: backup.sh
# Description: kingit's backup system 
# Script Maintainer: Rafael
# Version: 1.0
# Last Updated: November 3th 2015
##################################################
#
: <<'Descript'
O que é utilizado para os backups.

Data de inicio,
Data de termino,
Hora de inicio,
Hora de termino
Origem
Destino
Ponto de montagem
Espaço na Origem
Espaço no Destino

##################################################
Informações para Envio de email
Destinatarios
O que está sendo backupeado
##################################################
O que quero com esse sistema?
Descobrir exatamente e rastrear onde está cada um dos arquivos, e quantas cópias temos de cada um deles.
Centralizar o sistema de backup e Restore em um unico programa.
Ter um relatório mais analítico do que está sendo feito.

O que podemos conseguir nestes relatórios:

01. Quantidade de dados copiados, crescimento da base de dados. - Number of Files
	Quantos arquivos foram criados desde o ultimo backup - Number of created files
	Quantos arquivos foram deletados desde o ultimo backup - Number of deleted files
	Quantos arquivos foram transferidos

02. Tempo necessário para efetuar a cópia - Hora Fim - Hora Inicio

03. Espaço total Origem - Total file size
	
04. Espaço total Destino - Já está no cadastro do Destino no SQL

05. Qual departamento está produzindo mais arquivos - Difícil esse - Posso tentar fazer o backup por departamento, ai fica mais fácil.

06. Diferenças entre o arquivo original e o arquivo alterado - Literal data

07. armazenar o local do arquivo versionado e se o mesmo está disponível para recuperação - Verificar se o arquivo realmente existe na pasta diff

08. Maiores e menores arquivos copiados - Esse não vou conseguir - e também é inútil

09. Verificar sobre arquivos deletados - Este é importante mas não sei como tratar ainda

10. Informar Erros de Cópia - Este também é importante, também não sei como tratar ainda

11. Informar Espaço disponível - Verificar pelo df o espaço disponível e apresentar no relatório

12. Média de crescimento (Taxa de crescimento até a data Atual) - Esse vai ser fácil, vou apenas somar o Total transfered file size

13. Gerar Relatório - Semanal e Mensal - Vai ser o resumo disso tudo acima

14. Enviar tudo isto por email formatado - agora sim vem a zika rs

b --backup-dir --suffix
r - recursive
i - Itemize Changes
t - preserves modification times
#z - --compress-level=9 
v - Verbosity
h - Human Readable
l - links
p - permissions
E - executability
g - group
o - Owner
A - Preserve ACLs

Comando Final:
-bhaviAE --compress-level=9 --stats --backup-dir=/bkpdiff/`date +%F-%H:%M` --suffix=.old $ORIGEM $DESTINO

Fernando - NeoVia
Sergio
Em frente ao 618

Descript

#Inicia Variaveis para Conexão e Comandos SQL na base.
varMSQLC='mysql -ubackup -h10.0.99.76 -pEng123Form -Ddb_backups -B -N -e' #Mostra apenas os Dados
varMSQLCT='mysql -ubackup -h10.0.99.76 -pEng123Form -Ddb_backups -e' #Mostra a grade com os Campos das tabelas.

function Backup () {
	echo "foi aqui"
	BACKUPS=($($varMSQLC "SELECT COD FROM LinkBackup"))
	for i in ${!BACKUPS[@]}; do
		#Backup da Vez
		Link_O=$($varMSQLC "SELECT COD_ORIGEM FROM LinkBackup Where COD=${BACKUPS[$i]}")
		#Carregando Variaveis de Origem
		O_COD=$($varMSQLC "SELECT COD FROM Origem Where COD=$Link_O")
		O_Nome=$($varMSQLC "SELECT Nome FROM Origem Where COD=$Link_O")
		O_Local=$($varMSQLC "SELECT Share FROM Origem Where COD=$Link_O")
		O_IP=$($varMSQLC "SELECT IP FROM Origem Where COD=$Link_O")
		USUARIO=$($varMSQLC "SELECT Usuario FROM Origem Where COD=$Link_O")
		SENHA=$($varMSQLC "SELECT Senha FROM Origem Where COD=$Link_O")
		
		#Backup da Vez
		Link_D=$($varMSQLC "SELECT COD_DESTINO FROM LinkBackup Where COD=${BACKUPS[$i]}")
		#Carregando Variáveis de Destino
		D_COD=$($varMSQLC "SELECT COD FROM Destino Where COD=$Link_D")
		D_Nome=$($varMSQLC "SELECT Nome FROM Destino Where COD=$Link_D")
		D_Local=$($varMSQLC "SELECT Local FROM Destino Where COD=$Link_D")
		
		################################################
		DESCR="Backup de ${O_Nome[$i]} para ${D_Nome[$i]}" #Descrição do Backup, o que esta sendo feito
		################################################
		TIPOBKP="${O_Nome[$i]} para ${D_IP[$i]}"
		#Determina Comparilhamento que sera montado
		#USUARIO="adama" # será substituido pela chave publica SSH
		#SENHA="3ng3f0rm1931@@" # será substituido pela chave publica SSH
		echo "Criando o Diretório ${O_Local[$i]}"
		mkdir -p /mnt/${O_Local[$i]}
		echo "Montando a Parada lá"
		mount.cifs //${O_IP[$i]}/${O_Local[$i]} /mnt/${O_Local[$i]} -o user=$USUARIO,pass=$SENHA
		
		DADOBKP=/bkpdiff/logs/${O_Nome[$i]}_`date +%F`.log
		echo "Mostrando que a poha funcionou"
		#De onde sera copiado para onde.
		ORIGEM="/mnt/${O_Local[$i]}"
		#ARQUIVO=$(ls -t "/bkp_sql/SQL_RM/RMPRODUCAO*" | sed -n "1p")
		ARQUIVO="*"
		DESTINO="/${D_Local[$i]}/"
		
		DATA_ANTES=`date +%F` #Mostra a data em que foi realizado o backup para envio do assunto do email
		HORA_ANTES=`date +%X` #Marca Data e hora do inicio do backup
		#rsync -avz *.* $DESTINO >> $DADOBKP
		rsync -bhaviAE --compress-level=9 --stats --delete-after --ignore-errors --backup-dir=/bkpdiff/${O_Nome[$i]}/`date +%F`/bkp_${O_Local[$i]}_`date +%X` --suffix=.old $ORIGEM $DESTINO >> $DADOBKP
		#echo "fazendo o backup da parada"
		#sleep 10
		##Captacao dos dados e separacao das informacoes do log.
		T_Num_Files=$(cat $DADOBKP | grep "Number of files" | cut -d"(" -f1 | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/,//')
		T_Num_New_Files=$(cat $DADOBKP | grep "Number of created files" | cut -d"(" -f1 | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/,//') 
		T_Num_Del_Files=$(cat $DADOBKP | grep "Number of deleted files" | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/,//')
		T_Num_Copy_Files=$(cat $DADOBKP | grep "Number of regular files transferred" | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/,//')
		TMP_Total_Transf=$(cat $DADOBKP | grep "Literal data" | cut -d: -f2 | sed 's/ //;s/ $//' | sed 's/ bytes//')
		if $(echo $TMP_Total_Transf | grep -q K); then
			echo "Tem Kbites"
			T_Total_Transf=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
		elif $(echo $TMP_Total_Transf | grep -q M); then
			echo "Tem Mbites"
			Vlr=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
			T_Total_Transf=$(echo "$Vlr * 1024" | bc)
		elif $(echo $TMP_Total_Transf | grep -q G); then
			echo "Tem Gbites"
			Vlr=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
			T_Total_Transf=$(echo "($Vlr * 1024)* 1024" | bc)
		elif $(echo $TMP_Total_Transf | grep -q T); then
			echo "Tem Tbites"
			Vlr=$(echo "$TMP_Total_Transf" | sed 's/[a-Z]$//')
			T_Total_Transf=$(echo "(($Vlr * 1024)* 1024)* 1024" | bc)
		fi
		
		DATA_DEPOIS=`date +%F` #Mostra a data em que foi realizado o backup para envio do assunto do email
		HORA_DEPOIS=`date +%X` #Marca Data e hora do inicio do backup
		
		$varMSQLC "INSERT INTO Logs (DATA_INICIO, DATA_FIM, COD_ORIGEM, COD_DESTINO, HORA_INICIO, HORA_FIM, Num_Files, Num_New_Files, Num_Del_Files, Num_Copy_Files, Total_Transf) VALUES ('$DATA_ANTES', '$DATA_DEPOIS', '${O_COD[$i]}', ${D_COD[$i]}, '$HORA_ANTES', '$HORA_DEPOIS', '$T_Num_Files', '$T_Num_New_Files', '$T_Num_Del_Files', '$T_Num_Copy_Files', '$T_Total_Transf')"
		
		ID_LOG=$($varMSQLC "SELECT COD FROM Logs WHERE HORA_FIM='$HORA_DEPOIS' ORDER BY COD DESC")
		
		SAVEIFS=$IFS
		IFS=$(echo -en "\n\b")
		for f in $(cat "$DADOBKP" | sed -n '/^>f/p'); do 
			$varMSQLC "INSERT INTO Files (COD_LOGS, ARQUIVO, Excluido) VALUES ('$ID_LOG', '$f', 'false')"
		done
		for fd in $(cat "$DADOBKP" | sed -n '/^*deleting/p'); do 
			$varMSQLC "INSERT INTO Files (COD_LOGS, ARQUIVO, Excluido) VALUES ('$ID_LOG', '$fd', 'true')"
		done
		
		IFS=$SAVEIFS
		
		echo "Desmontando o compartilhamento ${O_Local[$i]}"
		umount /mnt/${O_Local[$i]}
		rm -R /mnt/${O_Local[$i]}
		read -p "Aperte [Enter] para iniciar o proximo backup "
	done

}

function LogBackup () {
	echo "NADA AINDA"
}

function MontaEmail () {
DESTINATARIOS="contato@kingit.com.br,yudy@kingit.com.br, andre.delgado@engeform.com.br" #Destinatarios de email- serão consumidos do banco de dados

#Configuracao para email
echo To: $DESTINATARIOS >> $LOG
echo From: backup.servidor >> $LOG
echo Subject: $TIPOBKP $DATA >> $LOG
#Fim da configuracao de email.
}

: <<'COMENTADO'

ORIGENSBKP=("ADM" "CCR" "RM") #Quais os backups que serão feitos - Também serão consumidos do Banco de dados.


#Informa onde sera armazenado o log do backup

LOG=/bkp_sql/logs/$NOMEBKP_`date +%H%M-%F`.log


#Montar Unidade HDDADM
mount.cifs $COMPARTILHAMENTO $DESTINO -o user=$USUARIO,pass=$SENHA

## Remove arquivos do local de destino
rm /media/sql67/*


COMENTADO

#IniciaVariaveis
Backup
#LogBackup
