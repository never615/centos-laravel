FROM centos:7

LABEL maintainer="never615 <never615@gmail.com>"

ENV REAL_IP_HEADER 1
ENV RUN_SCRIPTS 1

ENV fpm_conf /etc/php-fpm.conf
ENV www_conf /etc/php-fpm.d/www.conf
ENV php_vars /etc/php.d/docker-vars.ini

RUN rm -rf /etc/localtime && \
   ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# aliyun镜像
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup &&\
  curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &&\
  sed -i -e 's/http:\/\//https:\/\//g' /etc/yum.repos.d/CentOS-Base.repo &&\
  # wget-O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo &&\
  yum clean all &&\
  yum makecache



# 阿里云epel源
RUN yum update -y && \
  yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm && \
  sed -i 's|^#baseurl=http://download.fedoraproject.org/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel* && \
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
  # yum install -y epel-release

# 安装其他常用库
RUN yum install -y \
  deltarpm gcc-c++ libpng-devel \
  freetype-devel libxml2 libxml2-devel zlib-devel glib2-devel bzip2 \
  bzip2-devel ncurses-devel libaio numactl numactl-libs readline-devel \
  libcurl-devel e2fsprogs-devel krb5-devel libidn-devel openssl-devel \
  libxslt-devel libicu-devel libevent-devel libtool bison gd-devel \
  pcre-devel zip unzip ntpdate sqlite-devel expect expat-devel rsync \
  lsof lrzsz mlocate \
  git cmake autoconf

# 编译依赖
RUN yum install -y \
    # Various matrix decompositions are provided through integration with LAPACK,
    # or one of its high performance drop-in replacements
    # (eg. OpenBLAS, Intel MKL, Apple Accelerate framework, etc).
    openblas-devel \
    arpack-devel \
    lapack-devel \
    SuperLU-devel

# Install ngixn
RUN yum install -y nginx &&\
  \
  # forward request and error logs to docker log collector
  ln -sf /dev/stdout /var/log/nginx/access.log &&\
  ln -sf /dev/stderr /var/log/nginx/error.log &&\
  mkdir -p /usr/share/nginx/run


# Install PHP7.3
# RUN yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm &&\
RUN yum install -y http://mirrors.tuna.tsinghua.edu.cn/remi//enterprise/remi-release-7.rpm &&\
  yum-config-manager --enable remi-php73 &&\
  yum install -y php-fpm php-gd php-mysql php-mysqlnd php-pdo php-mcrypt \
  php-mbstring php-json php-cli php-xml php-pgsql php-pecl-redis php-opcache \
  php-common php-curl php-devel&&\
  mkdir -p /run/php-fpm

# 配置启用opcache
RUN echo "opcache.validate_timestamps=0    //生产环境中配置为0" >> /etc/php.d/10-opcache.ini &&\
  echo "opcache.revalidate_freq=0    //检查脚本时间戳是否有更新时间" >> /etc/php.d/10-opcache.ini &&\
  echo "opcache.memory_consumption=128    //Opcache的共享内存大小，以M为单位" >> /etc/php.d/10-opcache.ini &&\
  echo "opcache.interned_strings_buffer=16    //用来存储临时字符串的内存大小，以M为单位" >> /etc/php.d/10-opcache.ini &&\
  echo "opcache.max_accelerated_files=4000    //Opcache哈希表可以存储的脚本文件数量上限" >> /etc/php.d/10-opcache.ini &&\
  echo "opcache.fast_shutdown=1         //使用快速停止续发事件" >> /etc/php.d/10-opcache.ini

# Instal Swoole
RUN yum install -y php-pecl-swoole

# Install crontabs and supervisor
RUN yum install -y rsyslog crontabs supervisor

ADD conf/supervisord.conf /etc/supervisord.conf

# Copy our nginx config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
RUN rm -Rf /var/www/* &&\
  mkdir -p /var/www/html/
ADD conf/nginx-site.conf /etc/nginx/conf.d/default.conf

# tweak php-fpm config
RUN echo "cgi.fix_pathinfo=0" > ${php_vars} &&\
    echo "upload_max_filesize = 100M"  >> ${php_vars} &&\
    echo "post_max_size = 100M"  >> ${php_vars} &&\
    echo "memory_limit = 128M"  >> ${php_vars} && \
    touch /dev/shm/php-fpm.sock && \
    chown nginx:nginx /dev/shm/php-fpm.sock && \
    chmod 666 /dev/shm/php-fpm.sock && \
    sed -i \
        # -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        # -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        # -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        # -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        # -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        # -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/user = apache/user = nginx/g" \
        -e "s/group = apache/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = nobody/listen.owner = nginx/g" \
        -e "s/;listen.group = nobody/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/dev\/shm\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        -e "s/^;listen.backlog = 511$/listen.backlog = -1/" \
        ${www_conf}



#Add your cron file
# ADD conf/cron /etc/cron.d/crontabfile
# RUN chmod 0644 /etc/cron.d/crontabfile
# RUN chmod 0644 /etc/cron.d/crontabfile && \
  # touch /var/log/cron.log

#This will add it to the cron table (crontab -e)
# RUN crontab /etc/cron.d/crontabfile

# Add Scripts
ADD scripts/laravel.sh /laravel.sh
RUN chmod 755 /laravel.sh
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# copy in code
ADD src/ /var/www/html/
ADD errors/ /var/www/errors

EXPOSE 80

WORKDIR "/var/www/html"
CMD ["/start.sh"]
