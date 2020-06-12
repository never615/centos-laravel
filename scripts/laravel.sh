#!/bin/bash
echo '-------- run custom scripts ----------'
pwd

# supervisor
echo '-------- supervisor ----------'

touch /var/www/html/storage/logs/worker.log
touch /var/www/html/storage/logs/horizon.log

mkdir -p /etc/supervisor/conf.d
cp /var/www/html/conf/supervisor/* /etc/supervisor/conf.d

# crontab
echo '-------- crontab ----------'
sed -i '$a * * * * * nginx nginx /var/www/html/artisan schedule:run >> /dev/stdout 2>&1'  /etc/crontab

# Make writable dirs
echo '-------- Make writable dirs ----------'
chown -R nginx /var/www/html/storage
chgrp -R nginx /var/www/html/storage
chgrp -R 777 /var/www/html/storage


echo '-------- laravel command ----------'

# Execute artisan view:cache
php artisan view:cache

# Execute artisan config:cache
php artisan config:cache

# Execute artisan optimize
php artisan optimize

# migrate
php artisan migrate --force

#opcache
#/usr/local/bin/cachetool opcache:reset

echo '-------- run custom scripts end  ----------'
