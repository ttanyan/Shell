#!/bin/bash

array=("/mnt/smarthome/api-gateway_8101/logs" "/mnt/smarthome/jimi-tms-provider_8103/logs" "/mnt/smarthome/jimi-tms-web-smarthome_8102/logs" "/mnt/jimifile/tomcat-jimifile-8280/logs" "/mnt/jimi_aed/jimi-share-aed-9060/logs" "/mnt/download/tomcat7-downloadcn-9998/logs" "/mnt/jimi_dream_cart/jimi_dream_cart/logs" "/mnt/hydrant/jimi_hydrant/logs")
for element in ${array[@]}
do
#清空所有日志，统一删除三天前的日志
 find ${element} -mtime +3 -name "*.log" | xargs rm -rf
    for i in `find ${element} -name "*.log"`
     do
      cat /dev/null > ${i}

     done
done


#直接清空当前MysqlDeploy.shMysqlDeploy.shMysqlDeploy.sh日志
#!/bin/bash
array=("/usr/local/nginx/logs")
for element in ${array[@]}
do
    for i in `find ${element} -name "error.log"`
     do
      cat /dev/null > ${i}

     done
done
