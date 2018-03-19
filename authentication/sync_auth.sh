#!/bin/bash

shopt -s lastpipe
PORT=3333
LOG="sync_auth.log"
# Criar lista de clientes e seus enderecos
client_list="client_list.txt"
user_keys="users_ssh-keys.txt"
kingit_sec_key="credentials_king/id_rsa"
keys_path=".ssh/authorized_keys"
king_user="kingit-sec"

# criar authenticated_keys padrao
echo $(date +%F)
cat $client_list | while read client; do
  echo "Sincronizando Cliente: $client"
  cat $user_keys | while read user_key; do
    username_key=$(echo $user_key | cut -d" " -f3 | cut -d@ -f1)
    echo "incluindo chave para $username_key"
    # create a new user, create the .ssh folder and give the right permissions, insert the authorized_keys inside.
    ssh -p${PORT} -q -i ${kingit_sec_key} ${king_user}@$client "if ! grep -q '^${username_key}:' /etc/passwd; then \
      sudo /usr/sbin/adduser --disabled-password --gecos '' ${username_key}; \
      sudo /bin/mkdir -p /home/${username_key}/.ssh; \
      sudo /usr/bin/touch /home/${username_key}/${keys_path}; \
      sudo chmod -R 777 /home/${username_key}/${keys_path}; \
      sudo echo $user_key >> /home/${username_key}/${keys_path}; \
      sudo chown -R ${username_key}:${username_key} /home/${username_key}/.ssh; \
      sudo chmod -R 700 /home/${username_key}/.ssh; \
    fi" < /dev/null
  done
done
