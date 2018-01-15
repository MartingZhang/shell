#!/usr/bin/expect
#set enter "\n"
spawn ssh-keygen -t dsa
expect {
        "*(/root/.ssh/id_dsa):" {send "\n\r";exp_continue}
        "*(empty for no passphrase)" {send "\n\r";exp_continue}
        "*again" {send "\n\r"}
}
expect eof
