#!/bin/bash
echo "请输入查询的pid"
read pid
echo "请输入查询次数(每隔10s查询一次)"
read time
interval=0
   while(($interval < time))
   do
     let interval++
     echo "${interval}"
     echo $(date +"%y-%m-%d %H:%M:%S") >> /home/jimi/jimi_aed/Test/${pid}_proc_memlog.txt
     cat /proc/$pid/status | grep -E 'VmSize|VmRSS|VmData' >> /home/jimi/jimi_aed/Test/${pid}_proc_memlog.txt
     cpu=`top -n 1 -p $pid|tail -4|head -2|awk '{ssd=NF-4} {print $ssd}'`
     echo "CPU: " $cpu >> /home/jimi/jimi_aed/Test/${pid}_proc_memlog.txt
     echo $blank >> /home/jimi/jimi_aed/Test/${pid}_proc_memlog.txt
     sleep 10
done
