# Shell脚本寄存
记录一些常脚本，脚本内容仅作思路开拓之用.
仅供自己琢磨、修改，对于他人使用造成的不良后果自负！

#### fail2ban.sh
fail2ban一键脚本
```
bantime  = 604800
findtime  = 300
maxretry = 3
backend = auto
```
#### mysqlbackup.sh
数据库备份脚本，自动删除7天以前的备份

#### backup_split.sh
数据库分表分库分文件夹备份，并且按日期打包，自动删除7天以前的备份

#### cobbler.sh
一键部署cobbler无人值守系统安装

#### 服务器免交互密钥生成及分发
#### 下面两个配合使用
#### ssh-keygen.sh
服务器免交互生成公钥、私钥
### fenfa_sshkey.sh
批量分发公钥到各个服务器，并免密钥认证

#### ssh_key_pass.sh
ssh密钥对免交户批量分发脚本
useage: 
``` ./ssh_key_pass.sh ip ```(多个ip以空格分开)
