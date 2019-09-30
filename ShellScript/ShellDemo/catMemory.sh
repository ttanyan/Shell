#!/usr/bin/env bash
#查看服务实际使用进程
array=("work-order-web"  "service/api/" "service/web/" "service/canal/" "service/score/" "service/recharge/" "api-frc-gateway" "api-frc-biz" "provider" "eureka" "/service/task/" "/service/manager" \
"basedubbo" "jenkins")
for element in ${array[@]}
do
   ps -ef | grep ${element} >>hello.txt
   echo "" >>hello.txt
   #如果结果是在第二行需要将NR调整为1
   ps -ef| grep ${element}| awk 'NR==2' | awk '{print $2}'
   index=$(ps -ef| grep ${element}| awk 'NR==2' | awk '{print $2}')
   memray=$(cat /proc/${index}/status|awk 'NR==13' | awk '{print $2}')
   echo "scale=2; $memray/1024" | bc >>mem.txt
done