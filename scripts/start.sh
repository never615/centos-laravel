
echo '-------- run start scripts start  ----------'

# Enables 404 pages through php index
if [ ! -z "$PHP_CATCHALL" ]; then
 sed -i 's#try_files $uri $uri/ =404;#try_files $uri $uri/ /index.php?$args;#g' /etc/nginx/conf.d/default.conf
fi


# Enable custom nginx config files if they exist
if [ -f /var/www/html/conf/nginx/nginx.conf ]; then
  cp /var/www/html/conf/nginx/nginx.conf /etc/nginx/nginx.conf
fi

if [ -f /var/www/html/conf/nginx/nginx-site.conf ]; then
  cp /var/www/html/conf/nginx/nginx-site.conf /etc/nginx/conf.d/default.conf
fi



# sed -i "s/server_tokens off;/server_tokens on;/g" /etc/nginx/nginx.conf


# Pass real-ip to logs when behind ELB, etc
if [[ "$REAL_IP_HEADER" == "1" ]] ; then
 sed -i "s/#real_ip_header X-Forwarded-For;/real_ip_header X-Forwarded-For;/" /etc/nginx/conf.d/default.conf
 sed -i "s/#set_real_ip_from/set_real_ip_from/" /etc/nginx/conf.d/default.conf
 if [ ! -z "$REAL_IP_FROM" ]; then
  sed -i "s#172.16.0.0/12#$REAL_IP_FROM#" /etc/nginx/conf.d/default.conf
 fi
fi

# Set the desired timezone
# echo date.timezone=$(cat /etc/TZ) > /etc/php/conf.d/timezone.ini

# Display errors in docker logs
if [ ! -z "$PHP_ERRORS_STDERR" ]; then
  echo "log_errors = On" >> ${php_vars}
  echo "error_log = /dev/stderr" >> ${php_vars}
fi

echo '-------- run laravel scripts ----------'
pwd

# supervisor
echo '-------- supervisor ----------'

# touch /var/www/html/storage/logs/worker.log
touch /var/www/html/storage/logs/horizon.log

cp /var/www/html/conf/supervisor/* /etc/supervisord.d

# crontab
# echo '-------- crontab ----------'
# sed -i '$a * * * * * nginx nginx /var/www/html/artisan schedule:run >> /dev/null 2>&1'  /etc/crontab

echo '-------- Make dirs ----------'
mkdir /var/www/html/storage/framework/cache/data

# Make writable dirs
echo '-------- Make writable dirs ----------'
chown -R nginx /var/www/html/storage
chgrp -R nginx /var/www/html/storage
chmod -R 777 /var/www/html/storage


echo '-------- laravel command ----------'

# Execute artisan view:cache
php artisan view:cache

# Execute artisan config:cache
php artisan config:cache

# Execute artisan optimize
php artisan optimize

echo '-------- Make writable dirs2 ----------'
chown -R nginx /var/www/html/storage
chgrp -R nginx /var/www/html/storage
chmod -R 777 /var/www/html/storage

# migrate
php artisan migrate --force

php artisan storage:link

#opcache
#/usr/local/bin/cachetool opcache:reset

echo '-------- run laravel scripts end  ----------'

# Run custom scripts
if [[ "$RUN_SCRIPTS" == "1" ]] ; then
  if [ -d "/var/www/html/scripts/" ]; then
    # make scripts executable incase they aren't
    chmod -Rf 750 /var/www/html/scripts/*; sync;
    # run scripts in number order
    for i in `ls /var/www/html/scripts/`; do /var/www/html/scripts/$i ; done
  else
    echo "Can't find script directory"
  fi
fi



echo '-------- run start scripts end  ----------'


# Start supervisord and services
supervisord -n -c /etc/supervisord.conf
