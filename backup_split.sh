#!/bin/bash
#define var
set -x
user="root"
pass="zxa+47523166"
path="/opt/backup"
cmd="mysql -u$user -p$pass"
dump="mysqldump -u$user -p$pass --events -x --master-data=2"
#system function
. /etc/init.d/functions
. /etc/profile
#judge dir
function jdir(){
	if [ ! -e $path ];then
		mkdir $path -p
	fi
}
#dump database
function bk(){
	for dbname in `$cmd -e 'show databases;'|awk 'NR>1{print $0}'|grep -Ev "Database|information_schema|performance_schema|mysql"`
	do
		for tname in `$cmd -e "show tables from $dbname"|sed "1d"`
		do
			mkdir $path/$dbname -p
			$dump $dbname $tname|gzip >$path/$dbname/${dbname}_${tname}_$(date +%F).sql.gz
			if [ -e $path/$dbname/${dbname}_${tname}_$(date +%F).sql.gz ];then
				echo "${dbname}_${tname}_$(date +%F)" >>$path/mysql_table.log
			fi

		done
		$dump $dbname|gzip >$path/$dbname/${dbname}_$(date +%F).sql.gz
		if [ -e $path/$dbname/${dbname}_$(date +%F).sql.gz ];then
			echo "${dbname}_$(date +%F)" >>$path/mysql_database.log
		fi
	done
}
function main(){
	jdir
	bk
}
main
find $path -type f -mtime +7 -exec rm -rf {} \;