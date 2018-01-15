#!/bin/bash

# 关闭selinux
setenforce 0
# 关闭firewalld防火墙
systemctl stop firewalld
# 下载阿里云镜像源
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# 安装cobbler
yum install cobbler cobbler-web pykickstart httpd dhcp tftp-server -y
# 启动httpd、cobblerd
systemctl start httpd
systemctl start cobblerd
# 检查cobbler配置存在的问题,逐一解决
cobbler check  
# 修改/etc/cobbler/settings文件中的server参数的值为提供cobbler服务的主机相应的IP地址或主机名，如server: 192.168.222.129
# 备份原文件
cp /etc/cobbler/settings{,.ori} 
sed -i 's/server: 127.0.0.1/server: 192.168.222.129/' /etc/cobbler/settings
# 修改/etc/cobbler/settings文件中的next_server参数的值为提供PXE服务的主机相应的IP地址，如next_server: 192.168.222.129
sed -i 's/next_server: 127.0.0.1/next_server: 192.168.222.129/' /etc/cobbler/settings
# 修改/etc/xinetd.d/tftp文件中的disable参数修改为 disable = no
# 备份源文件
cp /etc/xinetd.d/tftp{,.ori}
sed -i 's/disable.*= yes/disable                 = no/g' /etc/xinetd.d/tftp
# 执行 cobbler get-loaders 命令即可；否则，需要安装syslinux程序包，而后复制/usr/share/syslinux/{pxelinux.0,memu.c32}等文件至/var/lib/cobbler/loaders/目录中
cobbler get-loaders
# 修改rsync配置文件
sed -i s/"disable.*= yes"/"disable         = no"/g /etc/xinetd.d/rsync 
# 开启rsync的服务开机自启动
systemctl enable rsyncd 
# 开启rsync的服务
systemctl start rsyncd 
# 生成密码来取代默认的密码，更安全
openssl passwd -1 -salt 'renjunjie' '123456'
sed -i s/'default_password_crypted:.*'/'default_password_crypted: "$1$renjunji$G7LpR5255qFguHrw7E0KP\/"'/g /etc/cobbler/settings
# 安装cman fence-agents
yum install -y cman fence-agents
# 其他一些没有提示报错的小修改
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
sed -i 's/pxe_just_once: 0/pxe_just_once: 1/' /etc/cobbler/settings
systemctl restart cobblerd.service
cobbler check
# 配置dhcp
cat > /etc/dhcp/dhcpd.conf <<EOF
subnet 192.168.222.0 netmask 255.255.255.0 {
option domain-name-servers 223.5.5.5;
option routers 192.168.222.1;
range dynamic-bootp 192.168.222.100 192.168.222.250;
option subnet-mask 255.255.255.0;
next-server $next_server;
default-lease-time 43200;
max-lease-time 86400;
}
EOF
# 同步cobbler的配置，可以看到同步干了哪些事
cobbler sync  
# 设置开机自启动
systemctl enable dhcpd.service
systemctl enable rsyncd.service
systemctl enable tftp.service 
systemctl enable httpd.service 
systemctl enable cobblerd.service
systemctl restart dhcpd.service
systemctl restart rsyncd.service
systemctl restart tftp.service 
systemctl restart httpd.service
systemctl restart cobblerd.service
# 挂在镜像
mount /dev/cdrom /mnt
# 导入镜像
cobbler import --path=/mnt/ --name=CentOS-7.0-x86_64 --arch=x86_64
# 查看镜像列表
cobbler distro list
# 镜像存放目录，cobbler会将镜像中的所有安装文件拷贝到本地一份，放在/var/www/cobbler/ks_mirror下的CentOS-6.6-x86_64目录下。因此/var/www/cobbler目录必须具有足够容纳安装文件的空间 
cd /var/www/cobbler/ks_mirror/
# 配置ks.cfg（使用centos7的镜像的时候，注意下方的ks.cfg要在安装包那里删除掉@server-policy，这玩意在7没有的
cd /var/lib/cobbler/kickstarts/
mkdir CentOS-7.0-x86_64.cfg
cat CentOS-7.0-x86_64.cfg <<EOF
# kickstart template for Fedora 8 and later.
# (includes %end blocks)
# do not use with earlier distros

#platform=x86, AMD64, or Intel EM64T
# System authorization information
#auth  --useshadow  --enablemd5
authconfig --enableshadow --passalgo=sha512
# System bootloader configuration
bootloader --location=mbr --driveorder=sda --append="nomodeset crashkernel=auto rhgb quiet"
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --disabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot
logging --level=info
#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Shanghai
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Allow anaconda to partition the system as needed
#autopart
part /boot --fstype=ext4 --asprimary --size=200
part swap --asprimary --size=1024
part / --fstype=ext4 --grow --asprimary --size=200	 
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end
 
%packages
@base
@compat-libraries
@core
@debugging
@development
@dial-up
@hardware-monitoring
@performance
sgpio
device-mapper-persistent-data
systemtap-client
tree
lrzsz
telnet
nmap
dos2unix
%end
 
%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end
 
%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
%end
EOF
# 编辑profile，修改关联的ks文件
cobbler profile edit --name=CentOS-7.0-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7.0-x86_64.cfg
# 同步下cobbler数据，每次修改完都要镜像同步
cobbler sync
# 定制化安装
cobbler system add --name=ren --mac=00:0C:29:2E:FD:0E  --profile=CentOS-7.0-x86_64 --ip-address=192.168.222.120 --subnet=255.255.255.0 --gateway=192.168.222.1 --interface=eno16777736 --static=1 --hostname=linux_node --name-servers="223.5.5.5"
cobbler system list
cobbler sync
