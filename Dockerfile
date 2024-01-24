FROM ubuntu:22.04

LABEL maintainer="never615 <never615@gmail.com>"

# define script variables
ARG ENV=prod
ARG PHP_VERSION=8.3
ARG TZ=Asia/Shanghai

ARG WWWGROUP
ARG NODE_VERSION=20
ARG POSTGRES_VERSION=15

WORKDIR /var/www/html


ENV REAL_IP_HEADER 1
ENV RUN_SCRIPTS 1
ENV php_vars /etc/php/8.3/cli/conf.d/docker-vars.ini
ENV php_vars_dir /etc/php/8.3/cli/conf.d



#禁用任何交互式提示
ENV DEBIAN_FRONTEND noninteractive
# ENV SUPERVISOR_PHP_COMMAND="/usr/bin/php -d variables_order=EGPCS /var/www/html/artisan serve --host=0.0.0.0 --port=80"


# modify root password
RUN echo 'root:admin123' | chpasswd

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# 安装其他常用库 lrzsz
RUN apt-get update \
    && apt-get install -y rsyslog cron wget \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ngixn
# forward request and error logs to docker log collector
RUN apt-get update &&\
  apt-get install -y nginx &&\
  ln -sf /dev/stdout /var/log/nginx/access.log &&\
  ln -sf /dev/stderr /var/log/nginx/error.log &&\
  mkdir -p /usr/share/nginx/run &&\
  apt-get clean &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# RUN dnf install -y \
#   deltarpm gcc-c++ libpng-devel freetype-devel libxml2 libxml2-devel zlib-devel glib2-devel bzip2 \
#   bzip2-devel ncurses-devel libaio numactl numactl-libs readline-devel \
#   libcurl-devel e2fsprogs-devel krb5-devel libidn-devel openssl-devel \
#   libxslt-devel libicu-devel libevent-devel libtool bison gd-devel \
#   pcre-devel zip unzip ntpdate sqlite-devel expect expat-devel rsync \
#   lsof lrzsz mlocate git cmake autoconf net-tools && \
#   dnf clean all && \
#   rm -rf /var/cache/dnf   

# # 编译依赖 
# RUN yum install -y \
#     # Various matrix decompositions are provided through integration with LAPACK,
#     # or one of its high performance drop-in replacements
#     # (eg. OpenBLAS, Intel MKL, Apple Accelerate framework, etc).
#     openblas-devel \
#     arpack-devel \
#     lapack-devel \
#     SuperLU-devel  




# install php
RUN apt-get update \
    && mkdir -p /etc/apt/keyrings \
    && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils librsvg2-bin fswatch \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php${PHP_VERSION}-cli php${PHP_VERSION}-dev \
       php${PHP_VERSION}-pgsql php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-gd php${PHP_VERSION}-curl php${PHP_VERSION}-imap php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring \
       php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath php${PHP_VERSION}-soap php${PHP_VERSION}-intl php${PHP_VERSION}-readline \
       php${PHP_VERSION}-ldap php${PHP_VERSION}-msgpack php${PHP_VERSION}-igbinary php${PHP_VERSION}-redis php${PHP_VERSION}-swoole \
       php${PHP_VERSION}-memcached php${PHP_VERSION}-pcov php${PHP_VERSION}-imagick php${PHP_VERSION}-xdebug \
    && curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && npm install -g pnpm \
    && npm install -g bun \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get install -y mysql-client \
    && apt-get install -y postgresql-client-$POSTGRES_VERSION \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pecl install mongodb


# 配置启用opcache
# RUN echo "opcache.validate_timestamps=0    //生产环境中配置为0" >> ${php_vars_dir}/10-opcache.ini &&\
#   echo "opcache.revalidate_freq=0    //检查脚本时间戳是否有更新时间" >> ${php_vars_dir}/10-opcache.ini &&\
#   echo "opcache.memory_consumption=128    //Opcache的共享内存大小，以M为单位" >> ${php_vars_dir}/10-opcache.ini &&\
#   echo "opcache.interned_strings_buffer=16    //用来存储临时字符串的内存大小，以M为单位" >> ${php_vars_dir}/10-opcache.ini &&\
#   echo "opcache.max_accelerated_files=4000    //Opcache哈希表可以存储的脚本文件数量上限" >> ${php_vars_dir}/10-opcache.ini &&\
#   echo "opcache.fast_shutdown=1         //使用快速停止续发事件" >> ${php_vars_dir}/10-opcache.ini


#supervisord
ADD conf/supervisord.conf /etc/supervisord.conf
# ADD conf/supervisord.d/laravel-queue.ini /etc/supervisord.d/laravel-queue.ini
COPY conf/supervisord.d/ /etc/supervisord.d/




# Copy our nginx config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
RUN rm -Rf /var/www/* &&\
  mkdir -p /var/www/html/
ADD conf/nginx-site.conf /etc/nginx/conf.d/default.conf

#Add your cron file
ADD conf/cron /etc/cron.d/crontabfile
RUN chmod 0644 /etc/cron.d/crontabfile


# Add Scripts
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

ADD scripts/horizon_exit.sh /horizon_exit.sh
RUN chmod 755 /horizon_exit.sh

# copy in code
ADD src/ /var/www/html/
ADD errors/ /var/www/errors


RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.3

# RUN groupadd --force -g $WWWGROUP sail
# RUN useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 sail

# COPY start-container /usr/local/bin/start-container
# COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini ${php_vars}
# RUN chmod +x /usr/local/bin/start-container

EXPOSE 80

WORKDIR "/var/www/html"
CMD ["/start.sh"]
