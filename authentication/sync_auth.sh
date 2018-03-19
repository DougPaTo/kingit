#!/bin/bash

shopt -s lastpipe
PORT=3333
LOG="sync_auth.log"
# Criar lista de clientes e seus enderecos
client_list="client_list.txt"
user_keys="users_ssh-keys.txt"
kingit_sec_key="credentials_king/id_rsa"
keys_path="/keys/authorized_keys"

# criar authenticated_keys padrao
echo $(date +%F)
cat $client_list | while read client; do
  echo "Sincronizando Cliente: $client"
  echo "limpando chaves anteriores"
  ssh -p${PORT} -q -i ${kingit_sec_key} kingit-sec@$client "/bin/rm -rf $keys_path" < /dev/null
  cat $user_keys | while read user_key; do
    username_key=$(echo $user_key | cut -d" " -f3 | cut -d@ -f1)
    echo "incluindo chave para $username_key"
    ssh -p${PORT} -q -i ${kingit_sec_key} kingit-sec@$client "echo $user_key >> $keys_path;if grep -x '^${username_key}:' /etc/passwd; then echo 'ja existe'; else sudo /usr/sbin/adduser --disabled-password --gecos '' ${username_key}; fi" < /dev/null
  done
done
