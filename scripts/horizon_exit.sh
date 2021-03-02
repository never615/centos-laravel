#!/bin/sh
# 监控进程是否存在,不存在则退出,存在则循环检查
php /var/www/html/artisan horizon:terminate
supervisorctl stop laravel-horizon:*
while true;do
        count=`ps -ef|grep "horizon:work" |grep -v grep`
        if [ "$?" != "0" ];then
echo ">>>>no horizon:work"
exit
else
echo ">>>>horizon is runing..."
fi
sleep 1
done
