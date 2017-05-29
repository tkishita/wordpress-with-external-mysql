FROM centos:7
MAINTAINER kishitat

#install php,httpd,mysql
RUN yum install -y epel-release && \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
    yum install -y --enablerepo=remi,remi-php71 php php-devel php-mbstring php-pdo php-gd httpd mariadb mariadb-server php-mysql wget

#modify php config
RUN sed -i -e "s@;date.timezone =@date.timezone = \"Asia/Tokyo\"@" /etc/php.ini

#edit httpd setting
RUN mkdir -p /opt/httpd/logs && \
    sed -i -e "s/Listen 80/Listen 8080/" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s@ErrorLog .*@ErrorLog /opt/httpd/logs/error_log@" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s@    CustomLog .*@    CustomLog "/opt/httpd/logs/access_log" combined@" /etc/httpd/conf/httpd.conf    
    
#download wordpress
RUN cd /root/ && \
    curl -LO https://wordpress.org/latest.tar.gz && \
    tar -xzvf latest.tar.gz && \
    cp -R /root/wordpress/* /var/www/html && \
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

#edit wordpress config
RUN sed -i -e "s/'database_name_here'/getenv ('DB_NAME')/" /var/www/html/wp-config.php && \
    sed -i -e "s/'username_here'/getenv ('DB_USER')/" /var/www/html/wp-config.php && \
    sed -i -e "s/'password_here'/getenv ('DB_PASSWORD')/" /var/www/html/wp-config.php && \
    sed -i -e "s/'localhost'/getenv ('MYSQL_PORT_3306_TCP_ADDR')/" /var/www/html/wp-config.php && \
    sed -i -e "s/'username_here'/getenv ('DB_USER')/" /var/www/html/wp-config.php
    
RUN chown -R 999:999 /opt && \
    chown -R 999:999 /run && \
    chown -R 999:999 /var/www

#create startup shell and add permmision
RUN mkdir /shells/&& \ 
    echo "#!/bin/bash"  > /shells/start.sh && \
    echo "mysqld_safe &"  >> /shells/start.sh && \
    echo "apachectl -DFOREGROUND "  >> /shells/start.sh && \
    chmod a+x /shells/start.sh


#EXPOSE port 8080 for web
EXPOSE 8080

#define env variables
ENV DB_NAME wp_content
ENV DB_USER wp_user
ENV DB_PASSWORD 12345
ENV DB_HOST localhost

USER 999

ENTRYPOINT /shells/start.sh
