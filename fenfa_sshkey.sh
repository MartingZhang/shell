#!/usr/bin/expect
if { $argc != 2 } {
 send_user "usage: expect fenfa_sshkey.exp file host\n"
 exit
}
#define var
set file [lindex $argv 0]
set host [lindex $argv 1]
set password "123456"
#spawn scp /etc/hosts root@10.0.0.142:/etc/hosts
#spawn scp -P52113 $file oldboy@$host:$dir
#spawn ssh-copy-id -i  $file "-p 52113 oldboy@$host"
spawn ssh-copy-id -i  $file "-p 22 root@$host"
expect {
        "yes/no"    {send "yes\r";exp_continue}
        "*password" {send "$password\r"}
}
expect eof
