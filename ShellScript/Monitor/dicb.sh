#************************************************************************#
#  Filrname     :               DICB.sh					 #
#  Author       :               TLW 					 #
#  CreateDate   :               2019-08-02				 #
#  Description  :               this script is mointoring the linux Disk #
#                               CPU 、RAM、Bandwidth、if used more than  #
#                               sum 90%,then it will send a alarm email. #
#************************************************************************#


#!/bin/bash
email_logfile="/home/jimi/jimi_aed/DICB/logDetails.txt";

total=0
system=0
user=0
i=0
 
time=`date "+%Y-%m-%d %k:%M"`
day=`date "+%Y-%m-%d"`
minute=`date "+%k:%M"`

echo "############ 统计开始：$day $minute ###############" >> ${email_logfile}
 
#带宽使用情况
echo -e "\t\t">>${email_logfile}
echo "###################带宽利用率######################" >>${email_logfile}
#循环五次，避免看到的是偶然的数据
while (( $i<5 ))
do
rx_before=$(cat /proc/net/dev | grep 'ens33' | tr : " " | awk '{print $2}')
tx_before=$(cat /proc/net/dev | grep 'ens33' | tr : " " | awk '{print $10}')
sleep 2
#用sed先获取第7列,再用awk获取第2列，再cut切割,从第7个到最后，即只切割网卡流量数字部分
rx_after=$(cat /proc/net/dev | grep 'ens33' | tr : " " | awk '{print $2}')
tx_after=$(cat /proc/net/dev | grep 'ens33' | tr : " " | awk '{print $10}')
#注意下面截取的相差2秒的两个时刻的累计和发送的bytes(即累计传送和接收的位)
rx_result=`awk 'BEGIN{ printf "%.2f\n", ('$rx_after' - '$rx_before')/1024/1024/2*8}'`
tx_result=`awk 'BEGIN{ printf "%.2f\n", ('$tx_after' - '$tx_before')/1024/1024/2*8}'`
echo  "$time Now_In_Speed: $rx_result Mbps Now_OUt_Speed: $tx_result Mbps" >>${email_logfile}
let "i++"
done
#注意下面grep后面的$time变量要用双引号括起来
rx_result=$(cat logDetails.txt |grep "$time"|awk '{In+=$4}END{print In}')
tx_result=$(cat logDetails.txt |grep "$time"|awk '{Out+=$7}END{print Out}')
In_Speed=`awk 'BEGIN{ printf "%.2f\n", ('$rx_result'/5)}'`
Out_Speed=`awk 'BEGIN{ printf "%.2f\n", ('$tx_result'/5)}'`
#echo "#带宽的5次的平均值是：#" >>test.txt
echo  "$time In_Speed_average: $In_Speed Mbps Out_Speed_average: $Out_Speed Mbps" >>${email_logfile}
 
 
 
 
#CPU使用情况
#使用vmstat 1 5命令统计5秒内的使用情况，再计算每秒使用情况
echo -e "\t\t">>${email_logfile}
echo "###################CPU使情况#######################" >>${email_logfile}
#每2秒采样一次，连续采样3次
sar -u 2 3 >> ${email_logfile}

 
 

#磁盘已使用
disk_used=$(df -m | sed '1d;/ /!N;s/\n//;s/ \+/ /;' | awk '{used+=$3} END{print used}')
#磁盘总量
disk_totalSpace=$(df -m | sed '1d;/ /!N;s/\n//;s/ \+/ /;' | awk '{totalSpace+=$2} END{print totalSpace}')
#磁盘使用百分比
disk_percent=`awk 'BEGIN{printf "%.2f%%\n",('$disk_used'/'$disk_totalSpace')*100}'`
disk_integer=`awk 'BEGIN{printf "%.0f\n",('$disk_used'/'$disk_totalSpace')*100}'`
echo -e "\t\t">>${email_logfile}
echo "###################磁盘利用率######################" >>${email_logfile}
echo "磁盘总量: $disk_totalSpace" >>${email_logfile}
echo "磁盘已使用: $disk_used" >>${email_logfile}
echo "磁盘利用率百分比: $disk_percent" >>${email_logfile}

 
 
#内存使用情况
#获得系统总内存
memery_all=$(free -m | awk 'NR==2' | awk '{print $2}')
#获得占用内存（操作系统 角度）
system_memery_used=$(free -m | awk 'NR==2' | awk '{print $3}')
#获得buffer、cache占用内存
buffer_cache_used=$(free -m | awk 'NR==2' | awk '{print $6}')
#内存使用百分比
memery_percent=`awk 'BEGIN{ printf "%.2f%%\n", ('$system_memery_used' / '$memery_all')*100}'`
memery_integer=`awk 'BEGIN{ printf "%.0f\n", ('$system_memery_used' / '$memery_all')*100}'`
echo -e "\t\t">>${email_logfile}
echo "###################内存使用率######################" >>${email_logfile}
echo "系统总内存: $memery_all" >> ${email_logfile}
echo "系统使用内存: $system_memery_used" >> ${email_logfile}
echo "Buffer_catch使用内存: $buffer_cache_used" >> ${email_logfile}
echo "系统内存使用百分比: $memery_percent" >> ${email_logfile}
echo -e "\t\t">>${email_logfile}
echo "############ 结束本次统计：$day $minute ##########" >> ${email_logfile}

if [ $disk_integer -ge 5 ]
       then
	   perl "/home/jimi/jimi_aed/DICB/sendDiskMail.pl"
             
	else
	    alarmType="NO"
fi
	
if [ $memery_integer -ge 50 ]
	 then
	     perl "/home/jimi/jimi_aed/DICB/sendMemoryMail.pl"
             exit 0;
         else
	    alarmType="NO"
fi
