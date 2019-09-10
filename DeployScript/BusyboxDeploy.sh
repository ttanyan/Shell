#!/usr/bin/env bash
#获取busybox安装包，也可以其他机器下载后离线上传到目标机器
wget http://busybox.net/downloads/busybox-1.21.0.tar.bz2

#需要bzip2,要是机器没有安装的话
yum -y install bzip2
#或者离线安装bzip2
#tar zxvf bzip2-1.0.6.tar.gz
#cd bzip2-1.0.6/
#make -f Makefile-libbz2_so
#make && make install

tar -xvf busybox-1.21.0.tar.bz2
cd ./busybox-1.21.0
make defconfig
#注意，这里最好在相同操作系统的正常机器上进行静态链接
#防止动态链接还被挖矿病毒的动态库劫持，导致删除文件不成功
#如果条件不允许，第二点将会重点说明
make
make install
ln -s `pwd`/busybox /usr/bin/busybox
busybox|grep BusyBox |grep v