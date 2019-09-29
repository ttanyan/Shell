#!/usr/bin/env bash
email_logfile="/mnt/ShellSctipt/dicb/logDetails.txt"
title="警报!!!138服务器"
content="138服务器磁盘快爆了，赶快去整!!! 详情参看:${email_logfile}"
from="tanlianwang@jimilab.com,liangtianbo@jimilab.com,fudaibing@jimilab.com,cq_tangjie@jimilab.com"
echo "138服务器快爆了，赶快去整!!! 详情参看:${email_logfile}" | mail -s ${title} ${from}