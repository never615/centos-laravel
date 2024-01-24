改造自[https://gitlab.com/ric_harvey/nginx-php-fpm](https://gitlab.com/ric_harvey/nginx-php-fpm),基于centos.


容器退出需要执行命令:该命令会在队列任务执行完毕后关闭进程
sh /horizon_exist.sh


其他分支支持使用rockylinux作为基础镜像. centos不在使用了