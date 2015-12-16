#!/bin/bash
##################################################
# Name: bkpxen
# Description: Backup and Restore of XenServer Virtualizations
# Script Maintainer: Rafael
#
# Versão: 1.0
# Last Updated: October 25th 2015
##################################################
#Nome das virtualizações que deseja fazer backup
#VMS=("Servidor" "FileServer" "7Remoto" "VPN")
#VMS=("W8 Rafael" "SeaFile" "ServerMC")
#VMS=("DebianVPNTestes" "FluigPRD" "LORDSIDIOUS" "Portal_Aprovacoes" "w7x64_BI" "w7x64_Tarifador" "W2008_Portal_RH" "W2008_RM_APP_TESTE" "W2008Srv_Astrein")
#VMS=("Servidor" "FileServer" "VPN")
#VMS=("Servidor" "7Remoto" "VPN")
#VMS=("FluigPRD" "DebianVPNTestes" "w7x64_BI")
#VMS=("DebianVPNTestes")
##################################################
#Start of functions Backup and Restore
#

CLIENTE="R520-2"
VMS=("101.199" "FileServerAD" "Licensing_Server-Homolog" "OBBPLUS" "Solution" "VPN_TI" "W2008_NovoSGBD" "W2008R2_Externo(Essos)" "W2008R2_Matriz(Westeros)")
LOG=/mnt/bkpvms_$CLIENTE_$(date +%F).log

BASEM="10.0.99.77/kingit" #Database
BANCOM="backup" #Collection
#MCon="mongo 10.0.99.77/test --eval"
#mongo $BASEM --eval 'db.'$BANCOM'.insert
BKP_NAME="$_NOME"
T_DIA=`date +%F`
T_HORA=`date +%H:%M`
LOG="/tmp/log_"$BKP_NAME"_$T_DIA~$T_HORA.log"

DATA_ANTES="$T_DIA~$T_HORA" 
DATA_DEPOIS=`date +%F~%H:%M`

: << 'SCHEMA'

db.backup.insert({
"Servidor": "'$CLIENTE'",
"Report":{
"StartDate": "'$DATA_ANTES'", 
"EndDate": "'$DATA_DEPOIS'",
"Memory": "'$MEM_VM'",
"HardDisk": "'$HDD_VM'",
"CPU": "'$CPU_VM'", 
"TotalSize": "'$TOT_Size'",
"Files": ["Nenhum Arquivo"]}})

SCHEMA

function BackupVMs () {	
	tput clear
	echo "Inicio do Backup das VMs do $CLIENTE as $(date +%H:%M-%F)" >> $LOG
	echo "Virtualizações Backupeadas" >> $LOG
	tput cup 5 2
	for i in ${!VMS[@]}; do
		echo "Verificando UUID da VM ${VMS[$i]}"
		UUID=$(xe vm-list name-label=${VMS[$i]} | grep uuid | cut -d: -f2 | sed 's/^ //')
		#tput cup 6 2
		echo "Criando snapshot para backup"
		SNAPSHOT=$(xe vm-snapshot uuid=$UUID new-name-label=bkp_${VMS[$i]})
		#tput cup 7 2
		echo "Transformando Snapshot em VM"
		xe template-param-set is-a-template=false ha-always-run=false uuid=$SNAPSHOT
		#tput cup 8 2
		echo "Exportando VM"
		xe vm-export vm=$SNAPSHOT filename=/mnt/${VMS[$i]}_$CLIENTE.xva
		echo "/mnt/${VMS[$i]}_$CLIENTE.xva" >> $LOG
		#tput cup 9 2
		echo "Limpando VM após backup completo"
		xe vm-uninstall uuid=$SNAPSHOT force=true
		#tput cup 10 2
		echo "Backup da VM ${VMS[$i]} Realizado com Sucesso as $(date +%H:%M-%F)" >> $LOG
		echo "#################################################" >> $LOG
		#read -p "Pressione Enter"
	done
	#tput cup 12 2
	echo "Todos os backups concluidos"
	echo "Backup Finalizado as $(date +%H:%M-%F)" >> $LOG
}

function RestoreVMs () {
	tput clear
	echo "Iniciando processo de Restore das Vms em Novo Ambiente"
	tput cup 5 2
	for i in ${!VMS[@]}; do 
		echo "Iniciando Import da VM: bkp_${VMS[$i]}"
		xe vm-import filename=/mnt/${VMS[$i]}_$CLIENTE.xva
	done
}		

function menuPrincipal () {
	tput clear
	echo "Sistema de Backup e Restore XenServer"
	tput cup 4 2
	echo "O que deseja fazer?"
	echo "
  1. Efetuar o Backup das Vms.
  2. Restaurar as Vms em novo Ambiente. 
  9. Sair
  
  Qual a sua escolha:"
	tput cup 10 21
	read R_Mnu
	
	case $R_Mnu in
		1) BackupVMs ;;
		2) RestoreVMs ;;
		3) MDC ;;
		4) Colorize 5 "  Funcionalidade ainda em desenvolvimento. Voltando ao Menu Principal" ; sleep 3 ; menuPrincipal ;;
		5) Colorize 5 "  Funcionalidade atrelada do home.sh. Voltando ao Menu Principal" ; sleep 3 ; menuPrincipal ;; #CriaCompartilhamento ;;
		9) echo "  Valew Falow" ; exit;;
		*) echo "  Por favor escolha uma opção valida. Voltando para o Menu Principal."; sleep 3 ; menuPrincipal ;;
	esac
}

menuPrincipal


#Melhorias
#(pv -n Win7\ PTBR\ -\ x86-x64\ \[Maio\ 2012\]\ 6.1.7601.11651.iso > ~/Documents/W7.iso) 2>&1 | dialog --gauge "Copiando ISOs, aguarde..." 10 70 0
