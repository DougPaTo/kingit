#####!/bin/bash
#Marca Data e hora do inicio do backup
COMECO=`date +%F" as "%X`
#Informa onde sera armazenado o log do backup
LOG=/bkp_sql/logs/RM_`date +%H%M-%F`.log
#Mostra a data em que foi realizado o backup para envio do assunto do email
DATA=`date +%F`
#Descrição do Backup
TIPOBKP="Backup RMSQL"
DESCR="Backup do Banco de Dados SQL do RM do Servidor 10.0.99.60 (Produca�o) para nosso servidor de Backup"
#De onde sera copiado para onde.
ORIGEM=/media/SGBD/
DESTINO=/bkp_sql/SQL_RM/
#Determina Comparilhamento que sera montado
COMPARTILHAMENTO="//10.0.99.60/bkp_sql/bkp/copiar/"
USUARIO="Zaburama"
SENHA="Eng3Form@#"
#Destinatarios de email
DESTINATARIOS="contato@kingit.com.br,renan.petrucci@engeform.com.br,yudy@kingit.com.br,willyam.neves@engeform.com.br"

#Montar Unidade HDDADM
mount.cifs $COMPARTILHAMENTO $ORIGEM -o user=$USUARIO,pass=$SENHA

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
echo "Quantidade ocupada na Origem: " `du -sh $ORIGEM` >> $LOG
echo " " >> $LOG
echo "Backup iniciado em: $COMECO" >> $LOG
echo " " >> $LOG

#Backup com Versionamento
#rsync -britzvhl --progress --compress-level=9 --backup-dir=/bkp_sql/bkp_dif/bkp_rm_`date +%F"_AS_"%X` --suffix=.old $ORIGEM $DESTINO >> $LOG

#Backup sem Versionamento
rsync -avzh --progress $ORIGEM $DESTINO >> $LOG

TERMINO=`date +%F" as "%X`

echo " " >> $LOG
echo "Backup iniciado em: $COMECO" >> $LOG
echo "Backup terminado em: $TERMINO" >> $LOG

#echo "Espaço Contratado: 150Gb" >> $LOG
echo "Espaço utilizado no Destino: " `df -h $DESTINO` >> $LOG
echo "|##############################################" >> $LOG
echo " " >> $LOG
echo " " >> $LOG

#Envio do log após final do backup

ssmtp $DESTINATARIOS < $LOG
#echo Backup Finalizado com Sucesso em $TERMINO

#Remover Arquivos Copiados da Origem
rm -R /media/SGBD/* 
echo "Removendo arquivos Antigos"
#Desmontar a Unidade de REDE
umount /media/SGBD
./envio_67.sh
echo "Executando o segundo script"
