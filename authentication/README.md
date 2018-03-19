# Project Authentication

Packages necessarios no cliente

apt install rssh sudo

Depois de configurada a porta para acesso ao SSH como por exeplo PORT 3333 no arquivo /etc/ssh/sshd_config

conectado como root vc deve rodar os seguintes comandos:
```
wget goo.gl/nFoAG8 -O base_config.sh && bash base_config.sh
```
Isto ira configurar o usuario kingit-sec na maquina e alterar as permissoes de acordo para que o script sync_auth.sh funcione corretamente

Servidor kingit  
---------------
Baixe o repositorio authentication dentro da pasta Kingit para o servidor usando o commando: ``` git clone https://github.com/helladarion/kingit.git```
Dentro da pasta kingit/authentication voce ira encontrar alguns alguns arquivos principais como: ``` client_list.txt e users_ssh-keys.txt```
Esses arquivos sao importantes pois sao eles que devem ser alterados para cada nova inclusao de cliente e/ou inclusao de funcionario.
