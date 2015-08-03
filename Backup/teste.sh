#!/bin/bash

: <<'BLOCK'
TOTAL=`du -sh /bkp_sql/Mensal/ | cut -d/ -f1`


rsync -avz /bkp_sql/Mensal/ | pv -s $((10#$TOTAL)) arquivo > /dev/null


function VerificaAntigos(){
	PathBackup="/bkp_adm2/bkp_dif/"
	MesAtual=`date +%m`
	let MesAtual=MesAtual-1
	MesAtual=0$MesAtual
	#echo $MesAtual
	
	for delete in  $(ls -t $PathBackup | tac | sed -n "/[0-9][0-9][0-9][0-9]-$MesAtual-[0-9][0-9]/,/[0-9][0-9][0-9][0-9]-$-[0-9][0-9]/!p"); do
		echo "Removi este backup: $delete"
		rm -R $PathBackup$delete
	done
}

BLOCK

ORIGEM="/bkp_sql/SQL_RM/RMPRODUCAO*"
#ARQUIVO=
ARQUIVO=$(ls -t $ORIGEM | sed -n "1p" )

echo $ARQUIVO
