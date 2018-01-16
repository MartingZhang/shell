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
yum install -y fail2ban fail2ban-systemd fail2ban-sendmail
# https://github.com/fail2ban/fail2ban/archive/0.9.4.tar.gz

echo "Copy configure file..."
\cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.bak

echo "make configure file..."
cat >/etc/fail2ban/jail.conf<<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 604800
findtime = 300
maxretry = 3
backend  = auto
[ssh-iptables]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/secure
bantime  = 604800
findtime = 300
maxretry = 3
[sendmail]
enabled  = true
filter   = sendmail
action   = iptables-multiport[name=sendmail, port="pop3,imap,smtp,pop3s,imaps,smtps", protocol=tcp]
           sendmail-whois[name=sendmail, dest=you@example.com]
logpath  = /var/log/maillog
EOF

echo "Start fail2ban..."
systemctl restart fail2ban
systemctl enable fail2ban
tail /var/log/fail2ban.log
fail2ban-client status
fail2ban-client status ssh-iptables
