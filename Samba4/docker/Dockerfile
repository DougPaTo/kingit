FROM phusion/baseimage:0.10.1
MAINTAINER contact.rafaelpr@gmail.com

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ENV \
  SAMBA_VER="4.8.0"
  SAMBA_FOLDER="samba-${SAMBA_VER}"
  SAMBA_FILE="samba-${SAMBA_VER}.tar.gz"

RUN apt install -y acl attr autoconf bind9utils bison build-essential \
  debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
  libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
  libcap-dev libcups2-dev libgnutls28-dev libgpgme11-dev libjson-perl \
  libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl \
  libpopt-dev libreadline-dev nettle-dev perl perl-modules pkg-config \
  python-all-dev python-crypto python-dbg python-dev python-dnspython \
  python3-dnspython python-gpgme python3-gpgme python-markdown python3-markdown \
  python3-dev xsltproc zlib1g-dev wget
  
RUN wget -O /tmp/ https://download.samba.org/pub/samba/stable/${SAMBA_FILE} && tar -xvf /tmp/${SAMBA_FILE}

RUN /tmp/${SAMBA_FOLDER}/configure --prefix=/opt/samba --enable-debug --enable-selftest && make && make install

RUN export PATH=/opt/samba/bin/:/opt/samba/sbin/:$PATH

# Enabling SSH
RUN rm -f /etc/service/sshd/down

COPY id_rsa.pub /tmp/id_rsa.pub

RUN cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys && rm -f /tmp/id_rsa.pub

WORKDIR /opt

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*