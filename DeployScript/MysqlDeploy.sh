#!/bin/bash
#安装目录
contents="/usr/local/mysql"
#配置文件
myconfig="/etc/my.cnf"
#环境变量
environment="/etc/profile"
#下载
#wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz
#解压
tar -xvf mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz
#移动
mv mysql-5.7.26-linux-glibc2.12-x86_64 ${contents}
#创建mysql组和用户
groupadd mysql
#创建用户组，用户，数据目录，初始化数据
useradd -r -g mysql mysql
#将安装目录所有者及所属组改为mysql
chown -R mysql.mysql ${contents}
#在mysql目录下创建data目录
cd  ${contents}
mkdir data
#初始化之前先执行
#yum -y install numactl
#yum search libaio
#yum install libaio
#初始化数据
${contents}/bin/mysql_install_db --user=mysql --basedir=${contents} --datadir=${contents}/data --initialize
#编辑配置文件 /etc/my.cnf
#先清空
 >${myconfig}

echo "[mysqld]" >>${myconfig}
echo "datadir=${contents}/data" >>${myconfig}
echo "basedir=${contents}" >>${myconfig}
echo "socket=/tmp/mysql.sock" >>${myconfig}
echo "user=mysql" >>${myconfig}
echo "port=3306" >>${myconfig}
echo "character-set-server=utf8" >>${myconfig}
echo "skip-grant-tables" >>${myconfig}
echo "symbolic-links=0" >>${myconfig}
echo "[mysqld_safe]" >>${myconfig}
echo "log-error=/var/log/mysqld.log" >>${myconfig}
echo "pid-file=/var/run/mysqld/mysqld.pid" >>${myconfig}
#将mysql加入到服务，启动
cp ${contents}/support-files/mysql.server /etc/init.d/mysql
chkconfig mysql on
service mysqld start
#配置环境变量
echo "#mysql5.7" >>${environment}
echo "export PATH=\$PATH:${contents}/bin" >>${environment}
source ${environment}
source ${environment}
#设置密码
mysql -u root -p
use mysql;
update user set authentication_string=password\('t199628'\) where user='root';
flush privileges;

#设置远程连接
update user set host='%' where user = 'root';
flush privileges;
exit





