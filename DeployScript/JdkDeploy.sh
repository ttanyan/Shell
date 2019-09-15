#!/usr/bin/env bash
#运行说明，安装在指定的目录，否则环境变量无法生效
profile="/opt/middle"
#环境变量
environment="/etc/profile"
#下载jdk1.8.14  不知道为什么 这个无法在脚本上执行下载
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz"

#解压
tar zxvf jdk-8u141-linux-x64.tar.gz
#重命令
mv jdk-8u141-linux-x64  jdk1.8.0_141
#以追加的形式添加环境变量
echo "#jdk1.8"  >>${environment}
echo "export JAVA_HOME="${profile}"/jdk1.8.0_141" >>${environment}
echo "export CLASSPATH=\$:CLASSPATH:\$JAVA_HOME/lib/ " >>${environment}
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >>${environment}
#环境生效
source ${environment}
#检查安装
java -version



