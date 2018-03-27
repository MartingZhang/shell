#!/bin/sh
##create by mingongge at 2017-01-10
. /etc/init.d/functions
case "$1" in
start)
      rsync --daemon
      if [ $? -eq 0 ];then
         action "rsync is started" /bin/true
      else
         action "rsync is started" /bin/false
      fi
;;
stop)
     pkill rsync
     sleep 2
     if [ `ps -ef|grep rsync|grep -v grep |wc -l` -eq 0 ];then
         action "rsync is stoped " /bin/true
     else
         action "rsync is stoped " /bin/false
     fi
;;
restart)
    pkill rsync
    sleep 2     
    if [ `ps -ef|grep rsync|grep -v grep |wc -l` -eq 0 ];then
       rsync --daemon
       if [ $? -eq 0 ];then
          action "rsync is restarted" /bin/true
       fi
    fi
;;
*)
   echo "USAGE :{start|stop|restart}"
;;
esac
