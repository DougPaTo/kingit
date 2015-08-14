#!/bin/bash

#Iniciando as variaveis que serão utilizadas.
COMECO=`date +%F" as "%X` #Marca Data e hora do inicio do backup
DATA=`date +%F` #Mostra a data em que foi realizado o backup para envio do assunto do email
################################################
DESCR="Copia do Banco de Dados SQL do RM para o servidor de testes e homologação 10.0.99.67" #Descrição do Backup, o que esta sendo feito
################################################
TIPOBKP="Banco para 10.0.99.67"

#De onde sera copiado para onde.
ORIGEM="/bkp_sql/SQL_RM/"
ARQUIVO=$(ls -t "/bkp_sql/SQL_RM/RMPRODUCAO*" | sed -n "1p")
DESTINO=/media/sql67/

#Determina Comparilhamento que sera montado
COMPARTILHAMENTO="//10.0.99.67/BKP_ONTEM"
USUARIO="Administrador" # será substituido pela chave publica SSH
SENHA="" # será substituido pela chave publica SSH

DESTINATARIOS="contato@kingit.com.br,renan.petrucci@engeform.com.br,yudy@kingit.com.br,willyam.neves@engeform.com.br" #Destinatarios de email- serão consumidos do banco de dados


ORIGENSBKP=("ADM" "CCR" "RM") #Quais os backups que serão feitos - Também serão consumidos do Banco de dados.


#Informa onde sera armazenado o log do backup

LOG=/bkp_sql/logs/$NOMEBKP_`date +%H%M-%F`.log


#Montar Unidade HDDADM
mount.cifs $COMPARTILHAMENTO $DESTINO -o user=$USUARIO,pass=$SENHA

## Remove arquivos do local de destino
rm /media/sql67/*

#Configuracao para email
echo To: $DESTINATARIOS >> $LOG
echo From: backup.servidor >> $LOG
echo Subject: $TIPOBKP $DATA >> $LOG
#Fim da configuracao de email.
