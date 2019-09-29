#!/usr/bin/env bash
array=("/mnt/smarthome/api-gateway_8101/logs" "/mnt/smarthome/jimi-tms-provider_8103/logs" "/mnt/smarthome/jimi-tms-web-smarthome_8102/logs" "/mnt/jimifile/tomcat-jimifile-8280/logs" "/mnt/jimi_aed/jimi-share-aed-9060/logs" "/mnt/download/tomcat7-downloadcn-9998/logs" "/mnt/jimi_dream_cart/jimi_dream_cart/logs" "/mnt/hydrant/jimi_hydrant/logs")
for element in ${array[@]}
do
#清空所有日志，统一删除三天前的日志

   $(cat /proc/${element}/status | awk 'NR==13' | awk '{print $2}' /1024 )

done


cat /proc/78154/status | awk 'NR==13' | awk '{print $2}'/1024