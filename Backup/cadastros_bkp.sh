#!/bin/bash

##Cadastro de dados principais para o sistema##
#Inicia Variaveis para Conexão e Comandos SQL na base.
varMSQLC='mysql -urafael -h10.0.99.76 -pM21p04 -Ddev_backups -B -N -e' #Mostra apenas os Dados
varMSQLCT='mysql -urafael -h10.0.99.76 -pM21p04 -Ddev_backups -e' #Mostra a grade com os Campos das tabelas.

#É necessário instalar a chave publica no arquivo ~/.ssh/authorized_keys da Origem
varChave="$HOME/.ssh/chaveprivada"


function exibeTitulo(){ ##Ajusta o Titulo para que o mesmo fique centralizado
	tput clear
	let coluna=`tput cols`/2
	linha=2
	tput clear
	titulo=$1
	let vlrTitulo=${#titulo}
	for i in $(eval echo "{1..$vlrTitulo}"); do
		sublinhado+="#"
	done
	let coluna=coluna-vlrTitulo/2
	tput cup $linha $coluna
	echo ${Green}$titulo ${ResetColor}
	linha=3
	tput cup $linha $coluna
	echo $sublinhado
	sublinhado=""
}

function CadOrigens(){

	
	TEMDADOS=`$varMSQLC 'select ORIGEM.COD from ORIGEM'`

	if [ -z $TEMDADOS ]; then
		##Afixação dos campos##
		exibeTitulo "Cadastro de Dados para as Origens de Backup"
		tput cup 5 2
		echo -e "Digite o Nome da Origem. ex.: HDDADM : \c"
		tput cup 6 2
		echo -e "Digite o local. ex.: /dados/HDDADM/ : \c"
		tput cup 7 2
		echo -e "Digite o IP da Origem. ex.: 10.0.99.17 : \c"
		tput cup 8 2
		echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
		
		##Captação de Dados##
		tput cup 5 2
		echo -e "Digite o Nome da Origem. ex.: HDDADM : \c "
		read R_Nome
		tput cup 6 2
		echo -e "Digite o local. ex.: /dados/HDDADM/ : \c"
		read R_Local
		tput cup 7 2
		echo -e "Digite o IP da Origem. ex.: 10.0.99.17 : \c"
		read R_IP
		tput cup 8 2
		echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
		read R_SO
		tput cup 10 5
		echo -e "Iniciando testes de Conexão..."
		tput cup 11 5
		echo -e "Verificando tamanho total do disco e armazenando a informação"
		R_ESPACO=`ssh -p3851 -i $varChave root@$R_IP df $R_Local | tr -s ' ' | cut -d' ' -f2 | sed -n '/$*.[0-9]/p'` #Verificar o tamanho do HDD
		tput cup 12 5
		echo "Espaço em Kb: $R_ESPACO"
		tput cup 14 5
		echo "Gravando informações no Banco de Dados"
		$varMSQLC "INSERT INTO ORIGEM (Nome, Local_Origem, IP, Espaco_Total, SO) VALUES ('$R_Nome', '$R_Local', '$R_IP', '$R_ESPACO', '$R_SO')"
		sleep 2
		tput cup 15 5
		echo "Dados Gravados com sucesso"
		tput cup 16 0
		
	else
		exibeTitulo "Cadastro de Dados para as Origens de Backup" ##Exibindo Titulo Customizado##
		tput cup 5 2
		echo -e "Foram Enconstrados Registros no Banco de Dados. Deseja Exibi-los? S/N : \c"
		read R_Exibe

		if [ `echo $R_Exibe` = "S" ];then 
			tput cup 6 2
			$varMSQLCT 'select * from ORIGEM'
		else
			tput clear
			exibeTitulo "Já existem Registros no Banco de Dados" ##Exibindo Titulo Customizado##
			##Fixando Campos na Tela##
			tput cup 5 2
			echo -e "Digite o Nome da Origem. ex.: HDDADM : \c"
			tput cup 6 2
			echo -e "Digite o local. ex.: /dados/HDDADM/ : \c"
			tput cup 7 2
			echo -e "Digite o IP da Origem. ex.: 10.0.99.17 : \c"
			tput cup 8 2
			echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
			
			##Captação de Dados##
			tput cup 5 2
			echo -e "Digite o Nome da Origem. ex.: HDDADM : \c "
			read R_Nome
			tput cup 6 2
			echo -e "Digite o local. ex.: /dados/HDDADM/ : \c"
			read R_Local
			tput cup 7 2
			echo -e "Digite o IP da Origem. ex.: 10.0.99.17 : \c"
			read R_IP
			tput cup 8 2
			echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
			read R_SO
			tput cup 10 5
			echo -e "Iniciando testes de Conexão..."
			tput cup 11 5
			echo -e "Verificando tamanho total do disco e armazenando a informação"
			R_ESPACO=`ssh -p3851 -i $varChave root@$R_IP df $R_Local | tr -s ' ' | cut -d' ' -f2 | sed -n '/$*.[0-9]/p'` #Verificar o tamanho do HDD
			tput cup 12 5
			echo "Espaço em Kb: $R_ESPACO"
			tput cup 15 0
			echo "Gravando informações no Banco de Dados"
			$varMSQLC "INSERT INTO ORIGEM (Nome, Local_Origem, IP, Espaco_Total, SO) VALUES ('$R_Nome', '$R_Local', '$R_IP', '$R_ESPACO', '$R_SO')"
			sleep 2
			tput cup 16 5
			echo "Dados Gravados com sucesso"
			tput cup 17 0
		fi
	fi
}

function CadDestinos(){

	
	TEMDADOS=`$varMSQLC 'select Destino.COD from Destino'`

	if [ -z $TEMDADOS ]; then
		##Afixação dos campos##
		exibeTitulo "Cadastro de Dados para os Destinos de Backup"
		tput cup 5 2
		echo -e "Digite o Nome do Destino. ex.: Backup75ADM : \c"
		tput cup 6 2
		echo -e "Digite o local. ex.: /bkp_adm/ : \c"
		tput cup 7 2
		echo -e "Digite o IP da Origem. ex.: 10.0.99.75 : \c"
		#tput cup 8 2
		#echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
		
		##Captação de Dados##
		tput cup 5 2
		echo -e "Digite o Nome do Destino. ex.: Backup75ADM : \c"
		read R_Nome
		tput cup 6 2
		echo -e "Digite o local. ex.: /bkp_adm/ : \c"
		read R_Local
		tput cup 7 2
		echo -e "Digite o IP da Origem. ex.: 10.0.99.75 : \c"
		read R_IP
		tput cup 8 2
		#echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
		#read R_SO
		tput cup 10 5
		echo -e "Iniciando testes de Conexão..."
		tput cup 11 5
		echo -e "Verificando tamanho total do disco e armazenando a informação"
		R_ESPACO=`ssh -p3851 -i $varChave root@$R_IP df $R_Local | tr -s ' ' | cut -d' ' -f2 | sed -n '/$*.[0-9]/p'` #Verificar o tamanho do HDD
		tput cup 12 5
		echo "Espaço em Kb: $R_ESPACO"
		tput cup 14 5
		echo "Gravando informações no Banco de Dados"
		$varMSQLC "INSERT INTO Destino (Nome, Local, IP, Espaco_Total) VALUES ('$R_Nome', '$R_Local', '$R_IP', '$R_ESPACO')"
		sleep 2
		tput cup 15 5
		echo "Dados Gravados com sucesso"
		tput cup 16 0
		
	else
		exibeTitulo "Cadastro de Dados para os Destinos de Backup"
		tput cup 5 2
		echo -e "Foram Enconstrados Registros no Banco de Dados. Deseja Exibi-los? S/N : \c"
		read R_Exibe

		if [ `echo $R_Exibe` = "S" ];then 
			tput cup 6 2
			$varMSQLCT 'select * from Destino'
		else
			tput clear
			exibeTitulo "Já existem Registros no Banco de Dados" ##Exibindo Titulo Customizado##
			##Afixação dos campos##
			exibeTitulo "Cadastro de Dados para os Destinos de Backup"
			tput cup 5 2
			echo -e "Digite o Nome do Destino. ex.: Backup75ADM : \c"
			tput cup 6 2
			echo -e "Digite o local. ex.: /bkp_adm/ : \c"
			tput cup 7 2
			echo -e "Digite o IP da Origem. ex.: 10.0.99.75 : \c"
			#tput cup 8 2
			#echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
			
			##Captação de Dados##
			tput cup 5 2
			echo -e "Digite o Nome do Destino. ex.: Backup75ADM : \c"
			read R_Nome
			tput cup 6 2
			echo -e "Digite o local. ex.: /bkp_adm/ : \c"
			read R_Local
			tput cup 7 2
			echo -e "Digite o IP da Origem. ex.: 10.0.99.75 : \c"
			read R_IP
			tput cup 8 2
			#echo -e "Informe o Sistema operacional. L para Linux e W para Windows : \c" 
			#read R_SO
			tput cup 10 5
			echo -e "Iniciando testes de Conexão..."
			tput cup 11 5
			echo -e "Verificando tamanho total do disco e armazenando a informação"
			R_ESPACO=`ssh -p3851 -i $varChave root@$R_IP df $R_Local | tr -s ' ' | cut -d' ' -f2 | sed -n '/$*.[0-9]/p'` #Verificar o tamanho do HDD
			tput cup 12 5
			echo "Espaço em Kb: $R_ESPACO"
			tput cup 14 5
			echo "Gravando informações no Banco de Dados"
			$varMSQLC "INSERT INTO Destino (Nome, Local, IP, Espaco_Total) VALUES ('$R_Nome', '$R_Local', '$R_IP', '$R_ESPACO')"
			sleep 2
			tput cup 15 5
			echo "Dados Gravados com sucesso"
			tput cup 16 0
		fi
	fi
}

function CadDestinatarios(){

	
	TEMDADOS=`$varMSQLC 'select Destinatarios.COD from Destinatarios'`

	if [ -z $TEMDADOS ]; then
		##Afixação dos campos##
		exibeTitulo "Cadastro de Dados para os Destinatários de Relatórios de Backup"
		tput cup 5 2
		echo -e "Digite o Nome do Destinatario. ex.: Yudy : \c"
		tput cup 6 2
		echo -e "Digite o Email do Destinatario. ex.: yudy@kingit.com.br : \c"
				
		##Captação de Dados##
		tput cup 5 2
		echo -e "Digite o Nome do Destinatario. ex.: Yudy : \c"
		read R_Nome
		tput cup 6 2
		echo -e "Digite o Email do Destinatario. ex.: yudy@kingit.com.br : \c"
		read R_Email
		tput cup 7 5
		echo "Gravando informações no Banco de Dados"
		$varMSQLC "INSERT INTO Destinatarios (Nome, Email) VALUES ('$R_Nome', '$R_Email')"
		sleep 2
		tput cup 8 5
		echo "Dados Gravados com sucesso"
		tput cup 9 0
		
	else
		exibeTitulo "Cadastro de Dados para os Destinatários de Relatórios de Backup"
		tput cup 5 2
		echo -e "Foram Enconstrados Registros no Banco de Dados. Deseja Exibi-los? S/N : \c"
		read R_Exibe

		if [ `echo $R_Exibe` = "S" ];then 
			tput cup 6 2
			$varMSQLCT 'select * from Destinatarios'
		else
			tput clear
			exibeTitulo "Já existem Registros no Banco de Dados" ##Exibindo Titulo Customizado##
			##Afixação dos campos##
			exibeTitulo "Cadastro de Dados para os Destinatários de Relatórios de Backup"
			tput cup 5 2
			echo -e "Digite o Nome do Destinatario. ex.: Yudy : \c"
			tput cup 6 2
			echo -e "Digite o Email do Destinatario. ex.: yudy@kingit.com.br : \c"
					
			##Captação de Dados##
			tput cup 5 2
			echo -e "Digite o Nome do Destinatario. ex.: Yudy : \c"
			read R_Nome
			tput cup 6 2
			echo -e "Digite o Email do Destinatario. ex.: yudy@kingit.com.br : \c"
			read R_Email
			tput cup 7 5
			echo "Gravando informações no Banco de Dados"
			$varMSQLC "INSERT INTO Destinatarios (Nome, Email) VALUES ('$R_Nome', '$R_Email')"
			sleep 2
			tput cup 8 5
			echo "Dados Gravados com sucesso"
			tput cup 9 0
		fi
	fi
}


function ColetaDados(){
#Capitação dos dados iniciais para cadastro na base de dados.
clear
#Opção desejada
echo "Por favor digite a opção que deseja"
echo ""
echo "1. Cadastrar Origens"
echo "2. Cadastrar Destinos"
echo "3. Cadastrar Destinatários"
#echo "4. "
#echo "5. Avisos Urgentes"
#echo "7. Troca de senha por lista"
echo "9. Sair"
echo ""
read R_TMP

case $R_TMP in
	1) CadOrigens ;;
	2) CadDestinos ;;
	3) CadDestinatarios ;;
	#4) ListaSenha ;;
	#7) TrocaSenhaLista ;;
	9) echo "Valew Falow" ; exit;;
	*) echo "Por favor escolha uma opção valida. Voltando para o Menu Principal."; sleep 3 ; ColetaDados ;;
esac
}

ColetaDados
