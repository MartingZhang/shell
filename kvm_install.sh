#!/bin/bash
#====================================================
#	System Request:Centos 7+
#	Author:	Martin
#	Dscription: KVM
#	Version: 1.0
#====================================================

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;30m"
RedBG="\033[41;32m"
Font="\033[0m"

#notification information
Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

source /etc/os-release

check_system(){
    
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${Font} "
        INS="yum"
        echo -e "${OK} ${GreenBG} SElinux 设置中，请耐心等待，不要进行其他操作${Font} "
        setsebool -P httpd_can_network_connect 1
        echo -e "${OK} ${GreenBG} SElinux 设置完成 ${Font} "
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${Font} "
        INS="apt"
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${Font} "
        INS="apt"
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font} "
        exit 1
    fi

}

is_root(){
    if [ `id -u` == 0 ]
        then echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font} "
        sleep 3
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}" 
        exit 1
    fi
}

judge(){
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}

virt_install(){
    if [[ "${ID}" == "centos" ]];then
        ${INS} install qemu-kvm libvirt libguestfs-tools virt-install virt-manager libvirt-python ntpdate -y
    else
        ${INS} update
        ${INS} install qemu-kvm libvirt libguestfs-tools virt-install virt-manager libvirt-python ntpdate -y
    fi
    judge "安装 kvm 基础包 "
}

brctl_config(){
    brctl addbr br0
	brctl addif br0 eth0
	brctl stp br0 on
	ifconfig eth0 0
	dhclient br0
}

start_process_systemd(){
    systemctl enable libvirtd
    judge "libvirtd 添加开机自启动"
    systemctl start libvirtd
    judge "libvirtd 启动"
}


main(){
    is_root
    check_system
	virt_install
    start_process_systemd
    brctl_config
}

main
