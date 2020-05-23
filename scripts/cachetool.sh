#!/bin/bash
#用来处理 php opcache
#curl -sO http://gordalina.github.io/cachetool/downloads/cachetool.phar
#chmod +x cachetool.phar
#mv cachetool.phar /usr/local/bin/cachetool


# 配置启用opcache
# cat >> /etc/php/conf.d/10-opcache.ini << EOF
# opcache.validate_timestamps=0    //生产环境中配置为0
# opcache.revalidate_freq=0    //检查脚本时间戳是否有更新时间
# opcache.memory_consumption=128    //Opcache的共享内存大小，以M为单位
# opcache.interned_strings_buffer=16    //用来存储临时字符串的内存大小，以M为单位
# opcache.max_accelerated_files=4000    //Opcache哈希表可以存储的脚本文件数量上限
# opcache.fast_shutdown=1         //使用快速停止续发事件
# EOF

# 配置opcache的黑名单(即测试环境不启用)
#echo '/app/back_end/*/integration' >> /etc/php.d/opcache-default.blacklist
#echo '/app/back_end/*/test' >> /etc/php.d/opcache-default.blacklist

# supervisorctl restart php-fpm
