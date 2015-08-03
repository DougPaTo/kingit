#!/bin/bash

#Iniciando as variaveis que serão utilizadas.

#O que esta sendo backupeado
NOMEBKP=("ADM" "CCR" "RM")

#Marca Data e hora do inicio do backup
COMECO=`date +%F" as "%X`

#Informa onde sera armazenado o log do backup
LOG=/bkp_sql/logs/$NOMEBKP_`date +%H%M-%F`.log

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
