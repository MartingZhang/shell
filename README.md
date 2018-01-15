# Shell脚本寄存
记录一些常脚本，仅供自己琢磨、修改和方便使用，对于他人使用造成的不良后果自负！
### fail2ban.sh
fail2ban一键脚本
```
bantime  = 604800
findtime  = 300
maxretry = 3
backend = auto
```
### mysqlbackup.sh
数据库备份脚本，自动删除7天以前的备份

### backup_split.sh
数据库分表分库分文件夹备份，并且按日期打包，自动删除7天以前的备份
