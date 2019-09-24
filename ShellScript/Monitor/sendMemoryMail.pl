#!/usr/bin/perl
$to = '1075379406@qq.com';
$from = 'tanlianwang@jimilab.com';
$subject = 'The server 172.25.3.198 MEMORY Alarm';
$message = 'The server 198(172.25.3.198) MEMORY alarm, please take action for it. thanks! address:/home/jimi/jimi_aed/DICB/logDetails.txt';
open(MAIL, "|/usr/sbin/sendmail -t");
print MAIL "To: $to\n";
print MAIL "From: $from\n";
print MAIL "Subject: $subject\n";
print MAIL "Content-type: text/html\n";
print MAIL $message;
close(MAIL);
print "邮件发送成功\n";
