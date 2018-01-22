#[option] remote
passwd && systemctl start sshd

#[option] wipefs
wipefs -a /dev/sda

# 检查是否运行于UEFI模式
# 对于新电脑需要检查电脑主板是否是通过UEFI引导：
# efivar -l

#[1-gpt/efi]
#parted /dev/sda -s -a optimal mklabel gpt mkpart primary 500m 100% \
#		    mkpart primary 1m 500m && mkfs.ext4 /dev/sda1 && mount /dev/sda1 /mnt && \
#		    mkdir -p /mnt/boot/EFI && mkfs.fat -F32 /dev/sda2 && \
#		    mount /dev/sda2 /mnt/boot/EFI

#[1-mbr/bios]
parted /dev/sda -s -a optimal mklabel msdos mkpart primary 1m 100% && \
#        mkfs.ext4 /dev/sda1 && mount /dev/sda1 /mnt

#[2-pacman]
#sed -i -e '/163/! s/^Server/#Server/' /etc/pacman.d/mirrorlist && pacstrap /mnt base
echo "setopt no_nomatch" >> ~/.zshrc
source ~/.zshrc
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -O /etc/pacman.d/mirrorlist.bak https://www.archlinux.org/mirrorlist/?country=CN
sed -i 's/#Server/Server/g' /etc/pacman.d/mirrorlist.bak
rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist
cat <<- EOF >> /etc/pacman.conf
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
EOF
pacman -Syy
pacman -Sy archlinux-keyring 
pacman-key --populate archlinux 
pacman-key --refresh-keys
pacstrap /mnt base base-devel
#[2-rsync]
#rsync -azAXH --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found"} root@10.0.0.1:/ /mnt

#[3-config]
genfstab -U -p /mnt > /mnt/etc/fstab
arch-chroot /mnt /bin/bash
echo 'LANG=zh_CN.UTF-8' > /etc/locale.conf && echo 'KEYMAP=us' > /etc/vconsole.conf && echo 'arch' > /etc/hostname && \
sed -i -e 's/^#\(en_US.UTF-8\|zh_CN.UTF-8\|zh_CN.GBK\)/\1/' /etc/locale.gen && locale-gen && \
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat <<- EOF > /etc/pacman.conf
#<ip-address> <hostname.domain.org> <hostname>
127.0.0.1 localhost.localdomain localhost arch
::1   localhost.localdomain localhost arch
EOF
mkinitcpio -p linux
pacman -S ntfs-3g

#[4-efi]
#pacman -S grub efibootmgr && \
#        grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub && \
#        grub-mkconfig -o /boot/grub/grub.cfg

#[4-bios]
pacman -S grub && \
        grub-install --target=i386-pc /dev/sda && \
        grub-mkconfig -o /boot/grub/grub.cfg

#[option] tools
pacman -S base-devel net-tools vim emacs git tmux cscope ctags htop nmap tcpdump socat tree curl wget wput rsync sudo zsh dhcpcd ntp openssh && \
        sed -i -e 's/^#\s*\(%wheel.*NOPASSWD.*\)/\1/' /etc/sudoers && \
        sed -i -e 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/sshd_config && \
        sed -i -e 's/^#KillUserProcesses.*/KillUserProcesses=no/' /etc/systemd/logind.conf && \
        chsh -s /usr/bin/zsh && \
        systemctl enable dhcpcd ntpd sshd

#[option] kde
pacman -S xorg plasma konsole dolphin fcitx wqy-zenhei wqy-microhei adobe-source-han-sans-cn-fonts && \
        sed -i -e 's/^Current=/Current=breeze/' /etc/sddm.conf && \
        echo -e 'export GTK_IM_MODULE=fcitx\nexport QT_IM_MODULE=fcitx\nexport XMODIFIERS="@im=fcitx"' > ~/.xprofile && \
        systemctl enable sddm NetworkManager

#[option] swap
dd if=/dev/zero of=/swap bs=1M count=2048 && chmod 600 /swap && mkswap /swap && swapon /swap && echo '/swap none swap defaults 0 0' >> /etc/fstab
#fallocate -l 2G /swap && chmod 600 /swap && mkswap /swap && swapon /swap && echo '/swap none swap defaults 0 0' >> /etc/fstab

#[option] user
useradd -m -G wheel -s /usr/bin/zsh -p password username

#[option] samba
pacman -S samba && systemctl enable smbd && pdbedit -a -u username

passwd && exit
umount -R /mnt && reboot
