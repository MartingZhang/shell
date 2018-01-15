#!/bin/bash
# author:Mr.chen
# 2017-3-14
# description:SSH密钥批量分发

User=root
passWord=##Linux登录密码

function YumBuild(){

echo "正在安装epel源yum仓库，请稍后..."
cd /etc/yum.repos.d/ &&\
[ -d bak ] || mkdir bak
[ `find ./*.* -type f | wc -l` -gt 0 ] && find ./*.* -type f |  xargs -i mv {} bak/
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo &>/dev/null
yum -y clean all &>/dev/null
yum makecache &>/dev/null

}

echo "正在进行网络连接测试,请稍后..."
ping www.baidu.com -c2 >/dev/null ||(echo "无法连同外网，本脚本运行环境必须和外网相连！" && exit)
[ $# -eq 0 ] && echo "没有参数！格式为：sh $0 参数1...n" && exit 
rpm -q sshpass &>/dev/null || yum -y install sshpass &>/dev/null
if [ $? -gt 0 ];then
    YumBuild
    yum -y install sshpass &>/dev/null || (echo "sshpass build error！" && exit)
fi
[ -d ~/.ssh ] || mkdir ~/.ssh;chmod 700 ~/.ssh
echo "正在创建密钥对...."
rm -rf ~/.ssh/id_dsa ~/.ssh/id_dsa.pub
ssh-keygen -t dsa -f ~/.ssh/id_dsa -P "" &>/dev/null
for ip in $*
do
    ping $ip -c1 &>/dev/null 
    if [ $? -gt 0 ];then
        echo "$ip无法ping通请检查网络" 
        continue
    fi
    sshpass -p "$passWord" ssh-copy-id -i ~/.ssh/id_dsa.pub "-o StrictHostKeyChecking=no ${User}@$ip" &>/dev/null
    echo "$ip 密钥分发成功"
done
