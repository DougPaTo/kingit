#!/bin/bash

COMECO=`date +%F" as "%X`
LOG=/backups/logs/REMOVE_DIFS_`date +%H%M-%F`.log
DATA=`date +%F`
PARA="contato@kingit.com.br,renan.petrucci@engeform.com.br,yudy@kingit.com.br,willyam.neves@engeform.com.br"

function removedifs(){

	#Cabeçalho email
        echo To: $PARA >> $LOG
        echo From: backup.servidor >> $LOG
        echo Subject: REMOCAO DIFS BACKUP $DATA >> $LOG
	#Fim Cabeçalho
	echo "REMOCAO DE ARQUIVOS EXCEDENTES EFETUADO DIA: $DATA" >> $LOG
	echo "" >> $LOG
	MesAtual=`date +%m`	
	let MesAtual=MesAtual-1
        MesAtual=0$MesAtual
	
	volumes=(backups bkp_adm2 bkp_adm)
	for pasta in ${volumes[@]}; do
		PathBackup="/$pasta/bkp_dif/"
		echo "" >> $LOG
		echo "PASTA $pasta" >> $LOG
		echo "Estado Atual do Sistema: "$(df -h | grep -w $pasta) >> $LOG
		#echo "" >> $LOG
		for delete in  $(ls -t $PathBackup | tac | sed -n "/[0-9][0-9][0-9][0-9]-$MesAtual-[0-9][0-9]/,/[0-9][0-9][0-9][0-9]-$-[0-9][0-9]/!p"); do
                	echo "Removi este backup: $delete"
        	        rm -R $PathBackup$delete
	        done
		#echo "" >> $LOG
		echo "Estado do Apos Limpeza:  "$(df -h | grep -w $pasta) >> $LOG

	done

	ssmtp $PARA < $LOG
}
removedifs
#rm $LOG
