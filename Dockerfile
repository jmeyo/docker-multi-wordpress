FROM phusion/baseimage:0.9.10

MAINTAINER Jean-Christophe Meillaud <jc@houseofagile.com>

ENV HOME /root

## Install SSH for a specific user (thanks to public key)
ADD ./config/id_rsa.pub /tmp/your_key
RUN cat /tmp/your_key >> /root/.ssh/authorized_keys && rm -f /tmp/your_key

# Adapt those value with your specific data ;)
ENV MYSQL_HOST 172.17.0.112
ENV MYSQL_USER admin
ENV MYSQL_PASSWORD 9DbcND6vDl9I

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install nginx php5-fpm php5-mysql php-apc pwgen python-setuptools curl git unzip

# Wordpress Requirements and mysql client
RUN apt-get -y install mysql-client php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf

RUN rm /etc/nginx/sites-enabled/default

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Supervisor Config
RUN apt-get install -y supervisor
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
RUN mkdir -p /var/log/supervisor
ADD ./supervisord.conf /etc/supervisord.conf

# Install Wordpress
ADD http://wordpress.org/latest.tar.gz /usr/share/nginx/latest.tar.gz
RUN cd /usr/share/nginx/ && tar xvf latest.tar.gz && rm latest.tar.gz

# Add 5x error pages in wordpress raw dir
RUN mv /usr/share/nginx/html/5* /usr/share/nginx/wordpress

# Transfer wordpress config and languages data

# Add needed files here
ADD wordpress-config/ /root

# Wordpress Initialization and Startup Script
RUN mkdir -p /etc/my_init.d
ADD init_wordpress.sh /etc/my_init.d/init_wordpress.sh
ADD supervisor.sh /etc/my_init.d/supervisor.sh

# private expose
EXPOSE 80

CMD ["/sbin/my_init"]

