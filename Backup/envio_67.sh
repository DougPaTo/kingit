#!/bin/bash

#Marca Data e hora do inicio do backup
COMECO=`date +%F" as "%X`

#Informa onde sera armazenado o log do backup
LOG=/bkp_sql/logs/ENVIO_67_`date +%H%M-%F`.log

#Mostra a data em que foi realizado o backup para envio do assunto do email
DATA=`date +%F`

#Descrição do Backup
TIPOBKP="Banco para 10.0.99.67"
DESCR="Copia do Banco de Dados SQL do RM para o servidor de testes e homologação 10.0.99.67"

#De onde sera copiado para onde.
ORIGEM="/bkp_sql/SQL_RM/"
ARQUIVO=$(ls -t "/bkp_sql/SQL_RM/RMPRODUCAO*" | sed -n "1p")
DESTINO=/media/sql67/

#Determina Comparilhamento que sera montado
COMPARTILHAMENTO="//10.0.99.67/BKP_ONTEM"
USUARIO="Administrador"
SENHA="InfoMatriz193122"

#Destinatarios de email
DESTINATARIOS="contato@kingit.com.br,renan.petrucci@engeform.com.br,yudy@kingit.com.br,willyam.neves@engeform.com.br"

#Montar Unidade HDDADM
mount.cifs $COMPARTILHAMENTO $DESTINO -o user=$USUARIO,pass=$SENHA

## Remove arquivos do local de destino
rm /media/sql67/*

#Configuracao para email
echo To: $DESTINATARIOS >> $LOG
echo From: backup.servidor >> $LOG
echo Subject: $TIPOBKP $DATA >> $LOG
#Fim da configuracao de email.

echo  Backup Iniciado, e seguindo... Aguarde
echo " " >> $LOG
echo " " >> $LOG
echo "|##############################################" >> $LOG
echo $DESCR >> $LOG
echo " " >> $LOG
#echo "Quantidade ocupada na Origem: " `du -sh $ORIGEM` >> $LOG
echo " " >> $LOG
echo "Backup iniciado em: $COMECO" >> $LOG
echo " " >> $LOG

#Backup com Versionamento
#rsync -britzvhl --progress --compress-level=9 --backup-dir=/bkp_sql/bkp_dif/bkp_rm_`date +%F"_AS_"%X` --suffix=.old $ORIGEM $DESTINO >> $LOG

#Backup sem Versionamento
rsync -avzh --progress $ARQUIVO $DESTINO >> $LOG

TERMINO=`date +%F" as "%X`

echo " " >> $LOG
echo "Backup iniciado em: $COMECO" >> $LOG
echo "Backup terminado em: $TERMINO" >> $LOG

#echo "Espaço Contratado: 150Gb" >> $LOG
echo "Espaço utilizado no Destino: " `df -h $DESTINO` >> $LOG
echo "|##############################################" >> $LOG
echo " " >> $LOG
echo " " >> $LOG

function BackupNormal(){
: <<'CORTE'
	#Remove backups antigos
	if [ $((`ls /bkp_sql/Historico/ | wc -l`)) -ge 30 ]; then
		echo "Existem Backups com mais de 30 dias" >> $LOG
		echo "Serão removidos os seguintes backups antigos: " >> $LOG
		for i in `find /bkp_sql/Historico/ -name "*" -type d -mtime +30`; do
			echo "$i" >> $LOG
			rm -R $i
		done
	fi
CORTE
	PathBackup="/bkp_sql/Historico/"
	MesAtual=`date +%m`     
        let MesAtual=MesAtual-1
        MesAtual=0$MesAtual

	for delete in  $(ls -t $PathBackup | tac | sed -n "/[0-9][0-9][0-9][0-9]-$MesAtual-[0-9][0-9]/,/[0-9][0-9][0-9][0-9]-$-[0-9][0-9]/!p"); do
		echo "Removi este backup: $delete"
                #rm -R $PathBackup$delete
        done


	#Armazenando o backup anterior em pasta por data
	mkdir -p /bkp_sql/Historico/$DATA
	mv $ARQUIVO /bkp_sql/Historico/$DATA/
	#Remover Arquivos Copiados da Origem
	#rm -R /media//* 
}

function BackupMensal(){
	mkdir -p /bkp_sql/Historico/$DATA
	mkdir -p /bkp_sql/Mensal/$DATA
	cp $ARQUIVO /bkp_sql/Mensal/$DATA/
	mv $ARQUIVO /bkp_sql/Historico/$DATA/
	#Remover Arquivos Copiados da Origem
	#rm -R /media/SGBD/* 
}

function VerificaAntigos(){
        if [ $((`echo $DATA | cut -d- -f3`)) -eq 1 ]; then
                echo "Realização de backup Mensal" >> $LOG
                echo $DATA
                BackupMensal
        else
                echo "Backup Diário" >> $LOG
                echo $DATA
                BackupNormal
        fi
}
#Verifica os backups e ajusta para o local correto
VerificaAntigos

#Envio do log após final do backup
ssmtp $DESTINATARIOS < $LOG

#Desmontar a Unidade de REDE
umount $DESTINO
