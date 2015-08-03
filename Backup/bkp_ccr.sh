#####!/bin/bash
COMECO=`date +%F" as "%X`
LOG=/backups/logs/CCR_`date +%H%M-%F`.log
DATA=`date +%F`
#ORIGEM=/media/outro/
ORIGEM=/media/HDDCCR/
DESTINO=/backups/HDDCCR/
#ORIGEM=/home/kingit/pasta1/
#DESTINO=/home/kingit/pasta2/

#Montar Unidade HDDADM
mount.cifs //10.0.99.17/hddccr /media/HDDCCR -o user=administrator,pass=K1m0n00$

#Configuracao para email 
echo To: contato@kingit.com.br,renan.petrucci@engeform.com.br,yudy@kingit.com.br,willyam.neves@engeform.com.br >> $LOG
echo From: backup.servidor >> $LOG
echo Subject: Backup HDDCCR $DATA >> $LOG
#Fim da configuracao � de email.

echo  Backup Iniciado, e seguindo... Aguarde
echo " " >> $LOG
echo " " >> $LOG
echo "|##############################################" >> $LOG
#echo "Quantidade ocupada no servidor NOVELL ADM: " `du -sh $ORIGEM` >> $LOG
echo "Backup iniciado em: $COMECO" >> $LOG
echo " " >> $LOG

#rsync -brityzvhlx --progress  --compress-level=3 --backup-dir=../bkp`date +%F` --suffix=.old --rsh='ssh -p3851 -i /home/bkp_scripts/kingit-rsync-key' root@obra563.ddns$

#rsync -ritzvhl --progress --compress-level=9 /media/novel/ADM /HDDADM/ >> $LOG
rsync -britzvhl --progress --delete --compress-level=9 --backup-dir=/backups/bkp_dif/bkp_ccr_`date +%F"_AS_"%X` --suffix=.old $ORIGEM $DESTINO >> $LOG
#rsync -avzh --progress $ORIGEM $DESTINO >> $LOG

TERMINO=`date +%F" as "%X`

echo " " >> $LOG
echo "Backup iniciado em: $COMECO" >> $LOG
echo "Backup terminado em: $TERMINO" >> $LOG

#echo "Espaço Contratado: 150Gb" >> $LOG
echo "Espaço utilizado: " `df -h $DESTINO` >> $LOG
echo "|##############################################" >> $LOG
echo " " >> $LOG
echo " " >> $LOG

#Envio do log após final do backup

#echo -e "to: rafael@kingit.com.br\nsubject: NOVELL Backup `date +%F`\n"| (cat - && uuencode $LOG $DATA.txt) | ssmtp rafael@kingit.com.br
ssmtp contato@kingit.com.br,renan.petrucci@engeform.com.br,yudy@kingit.com.br,willyam.neves@engeform.com.br < $LOG
#echo Backup Finalizado com Sucesso em $TERMINO

#Desmontar a Unidade de REDE
umount /media/HDDCCR
