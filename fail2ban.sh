#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi


if [ "${PM}" = "yum" ]; then
    yum install python iptables rsyslog -y
    service rsyslog restart
    \cp /var/log/secure /var/log/secure.$(date +"%Y%m%d%H%M%S")
    cat /dev/null > /var/log/secure
elif [ "${PM}" = "apt" ]; then
    apt-get update
    apt-get install python iptables rsyslog -y
    /etc/init.d/rsyslog restart
    \cp /var/log/secure /var/log/secure.$(date +"%Y%m%d%H%M%S")
    cat /dev/null > /var/log/auth.log
fi

yum install -y epel-release
yum install -y fail2ban
# https://github.com/fail2ban/fail2ban/archive/0.9.4.tar.gz

echo "Copy configure file..."
\cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.bak
cat >/etc/fail2ban/jail.conf<<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 604800
findtime  = 300
maxretry = 3
backend = auto
[ssh-iptables]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/secure
bantime  = 604800
findtime  = 300
maxretry = 3
EOF

echo "Copy init files..."
if [ ! -d /var/run/fail2ban ];then
    mkdir /var/run/fail2ban
fi
if [ `/sbin/iptables -h|grep -c "\-w"` -eq 0 ]; then
    sed -i 's/lockingopt =.*/lockingopt =/g' /etc/fail2ban/action.d/iptables-common.conf
fi
if [ "${PM}" = "yum" ]; then
    sed -i 's#logpath  = /var/log/auth.log#logpath  = /var/log/secure#g' /etc/fail2ban/jail.local
    \wget -O /etc/init.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/0.11/files/redhat-initd
elif [ "${PM}" = "apt" ]; then
    ln -sf /usr/local/bin/fail2ban-client /usr/bin/fail2ban-client
    \cwget -O /etc/init.d/fail2ban https://raw.githubusercontent.com/fail2ban/fail2ban/0.11/files/debian-initd
fi
chmod +x /etc/init.d/fail2ban
cd ..

echo "Start fail2ban..."
/etc/init.d/fail2ban restart
tail /var/log/fail2ban.log
fail2ban-client status
fail2ban-client status ssh-iptables
