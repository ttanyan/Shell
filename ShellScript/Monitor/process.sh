#查询服务是否存在
#!/bin/bash
day=`date "+%Y-%m-%d"`
minute=`date "+%k:%M"`
port=$1
pid=
echo "================查询时间${day} ${minute}=================" >>process.log
netstat -nltp|grep ${port} >>process.log
pid=$(netstat -nltp|grep ${port} | awk '{print $7}')
if [ ! ${pid} ];
  then
    echo "die"
    echo "该端口:$1 的服务不存在" >>process.log
  else
    echo ${pid}
fi
