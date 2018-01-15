#!/bin/bash
set -x 
file=`date +%Y-%m-%d_%H:%M:%S`
backup=/soft/data/database
start=`date +%Y-%m-%d_%H:%M:%S`
echo -e "MySQL Backup Start：$start" >> $filedir/auto_backup.log
name="root"
pawd="chai5Bie"
if [ 'id -u' -ne 0 ]; then
    echo "Backup Fail, Please Using Root run again"
    sleep  2
    exit  0
fi
/usr/bin/mysqldump --databases ccnet_db -u$name -p$pawd > $backup/ccnet-`date +%Y-%m-%d`.sql
/usr/bin/mysqldump --databases seahub_db -u$name -p$pawd > $backup/seahub-`date +%Y-%m-%d`.sql
/usr/bin/mysqldump --databases seafile_db -u$name -p$pawd > $backup/seafile-`date +%Y-%m-%d`.sql
/usr/bin/mysqldump --all-databases -u$name -p$pawd > $backup/mysql-`date +%Y-%m-%d`.sql
cd $backup && tar czvf Mysql-`date +%Y-%m-%d`.sql.tar.gz *.sql
#find -type f -name *.sql -mtime +7 -exec rm -rf {} \;
if [ $? -eq 0 ];then
       end=`date +%Y-%m-%d_%H:%M:%S`
       echo -e "The end of mysql backup：$end\n" >> $filedir/auto_backup.log
       echo -e "MySQL Backup Success!\nBegin：$start\nEnd：$end" >> $filedir/auto_backup_success.log
else
    echo -e "MySQL Backup Failed!\nBegin：$start\nEnd：$end" >> $filedir/auto_backup_error.log
fi
#find -type f -mtime +7 | xargs rm -rf
find -type f -mtime +7 -exec rm -rf {} \;
