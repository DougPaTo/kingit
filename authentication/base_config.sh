#!/bin/bash

# for this to work we need to create a user in the client servers called kingit-sec using the command:
adduser --disabled-password --gecos '' kingit-sec
mkdir -p /keys/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClteF32zJRsCXoEiA62Ka+bAS3soPlnAeev5MqmYg7276vWbxpGi/g0xPBRulF7xKBJ2fNK/vdjuAxhCWnVJohUWYHnJ/drvN+ZdTmrBa2zXHSLHKr+3TCbZwRziPb1WNq90Nc4ScPavagPTxQeUlXhquAk862Yrt7xNVs6Q48kv3h+529NN8IlTz8wB6jVKk2gc3pPuts39aUj+QaIwSM+/KJEwbJ2KJvob9RiHt9zm2GR7ysuqJgcXHXLr1GdThQwF4BofHk32O/7F3ks77qy6Aj8OHxXZOZijloalY7bT0So9LFdY03JL6GzQAOCRiU7gqYFLhr5PmSxTZ9gri5 kingit-sec@debian" >"/keys/king_key"
sed -i "s/^#AuthorizedKeysFile/AuthorizedKeysFile/" /etc/ssh/sshd_config
sed -i "s|.ssh/authorized_keys2|/keys/king_key|" /etc/ssh/sshd_config
/etc/init.d/ssh restart
sed -i "/^root/a kingit-sec  ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers
