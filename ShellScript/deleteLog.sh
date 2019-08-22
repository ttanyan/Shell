#!/bin/bash

array=("/mnt/smarthome/api-gateway_8101/logs" "/mnt/smarthome/jimi-tms-provider_8103/logs" "/mnt/smarthome/jimi-tms-web-smarthome_8102/logs" "/mnt/jimifile/tomcat-jimifile-8280/logs" "/mnt/jimi_aed/jimi-share-aed-9060/logs" "/mnt/download/tomcat7-downloadcn-9998/logs" "/mnt/jimi_dream_cart/jimi_dream_cart/logs" "/mnt/hydrant/jimi_hydrant/logs")
for element in ${array[@]}
do
 find ${element} -mtime +3 -name "*.log" | xargs rm -rf
#清空所有日志，统一删除三天前的日志
    for i in `find ${element} -name "*.log"`
     do
      cat /dev/null > ${i}

     done
done


/mnt/shellScript/delete-3-log.sh

##!/bin/bash
## 非当天日志
#find /mnt/smarthome/api-gateway_8101/logs  -mtime +10 -name *.*.log | xargs du -sh
## 删除【非当天】的日志
#find /mnt/smarthome/jimi-tms-provider_8103/logs  -mtime +10 -name *.*.log | xargs rm -rf
## 查看/opt目录下，所有【当天】日志文件及大小
#find /mnt/smarthome/jimi-tms-provider_8103/logs -name *.log | xargs du -sh
## 清空/opt目录下所有【当天】的日志文件
#for i in `find /mnt/smarthome/api-gateway_8101/logs -name *.log`
#do
#  cat /dev/null > $i
#done

#find /mnt/smarthome/api-gateway_8101/logs -name "*.log" -exec  > "*.log" {} \;
#find /mnt/smarthome/jimi-tms-provider_8103/logs -name "*.log.*" -exec rm -rf {} \;
#find /mnt/smarthome/jimi-tms-web-smarthome_8102/logs -mtime +60 -name "*" -exec rm -rf {} \;

#find /mnt/jimifile/tomcat-jimifile-8280/logs -mtime +60 -name "*" -exec rm -rf {} \;
##aed
#find /mnt/jimi_aed/jimi-share-aed-9060/logs -mtime +30 -name "*" -exec rm -rf {} \;

#find /mnt/download/tomcat7-downloadcn-9998/logs -mtime +30 -name "*" -exec rm -rf {} \;

#find /mnt/jimi_dream_cart/jimi_dream_cart/logs -mtime +180 -name "*" -exec rm -rf {} \;

#find /mnt/hydrant/jimi_hydrant/logs -mtime +1 -name "*" -exec rm -rf {} \;