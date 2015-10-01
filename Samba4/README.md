# Samba4

Project | Description
------- | ---------
samba4deploy | Full auto deploy of samba4 server 

    O projeto consiste nos seguintes pontos:
    
    Função | Descritivo
    ------ | ----------    
    1. Servidor Samba4 | Instalação do Samba Server com administração facilitada utilizando plataforma windows e o RSAT http://www.microsoft.com/downloads/en/details.aspx?FamilyID=7d2f6ad7-656b-4313-a005-4e344e43997d&displaylang=en. As funções de servidor são equivalentes às encontradas no Windows Server 2008R2, toda a administração de DNS, usuário do Active Directory e Configurações de GPO.
    2. File Server como segundo AD com Samba4 | Para proteger e permitir os snapshots do AD e como melhor prática separamos os dados da rede da configuração do AD, fazendo com que este servidor apenas leia as informações do AD principal, porém também respondendo requisições de DNS, servindo de backup em caso o AD principal fique indisponível.
    3. Membro do AD como backup server ou File Server | Sistema para efetuar os backups de maneira local nos clientes que não quiserem o serviço de backup remoto, ou caso seja um windows server e quiserem utilizar o sistema de file server do linux também é um opção.
    
    Lixeira de rede: determinação de local com criação automática de novos usuários e repositórios para a lixeira de rede pessoal.
    Auditoria de acessos: para verificação do que está sendo feito na rede a possibilitando a rastreabilidade das informações.
    Criação automatizada de compartilhamentos e atalhos para uso em GPO no servidor
    
    O que precisa ser feito:
    - Backup com versionamento de informações.
    - Servidor de banco de dados para armazenamento dos logs dos backups, auditoria e demais itens.
    - Monitoramento: verificação de espaço, uso do processador, memória, etc.
    - Verificação de disco, chkdsk hddparam e outros verificadores.
    - Envio dos relatórios por email com status das atividades.

