#!/bin/bash

PHP_MEMORY_LIMIT=256M
PHP_POST_MAX_SIZE=128M
PHP_UPLOAD_MAX_FILESIZE=128M
NR_CPUS=$(grep -c ^processor /proc/cpuinfo) 

export DEBIAN_FRONTEND=noninteractive

##### Iptables
wget -O /etc/iptables.rules http://www.timdj.nl/iptables.rules
iptables-restore /etc/iptables.rules

echo '#!/bin/sh' > /etc/network/if-pre-up.d/iptables
echo '/sbin/iptables-restore < /etc/iptables.rules' >> /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables

##### nginx LEMP
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
echo 'deb http://nginx.org/packages/debian/ jessie nginx' >> /etc/apt/sources.list
echo 'deb-src http://nginx.org/packages/debian/ jessie nginx' >> /etc/apt/sources.list
apt-get update && apt-get install nginx

apt-get -y update && apt-get upgrade
apt-get -y install nginx mariadb-server mariadb-client php5-fpm php5-mysqlnd php5-curl php5-gd php-pear php5-imagick php5-mcrypt php5-memcache php5-xmlrpc php5-intl curl git unzip sudo pwgen
 

##### MYSQL
MYSQL_PASSWORD=${MYSQL_PASS:-$(pwgen -s 12 1)}

mysqladmin -u root password "$PASSWORD"
echo -e "$PASSWORD\nn\n\n\n\n\n " | mysql_secure_installation 2>/dev/null


##### PHP
sed -i 's/memory_limit = .*/memory_limit = '${PHP_MEMORY_LIMIT}'/' /etc/php5/cli/php.ini
sed -i 's/memory_limit = .*/memory_limit = '${PHP_MEMORY_LIMIT}'/' /etc/php5/fpm/php.ini
sed -i 's/post_max_size = .*/post_max_size = '${PHP_POST_MAX_SIZE}'/' /etc/php5/fpm/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = '${PHP_UPLOAD_MAX_FILESIZE}'/' /etc/php5/fpm/php.ini

echo "realpath_cache_size = 256k" >> /etc/php5/cli/php.ini


##### NGINX
sed -i 's/worker_processes .*/worker_processes '${NR_CPUS}'/' /etc/nginx/nginx.conf
sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size '${PHP_POST_MAX_SIZE}'/" /etc/nginx/nginx.conf

mkdir -p /var/www/html
chown www-data:www-data /var/www/html

cat >> /etc/php5/fpm/pool.d/www.conf <<EOL
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 10
pm.max_requests=500
EOL




#// Adminer
#// unattended upgrades
#// config optimalisatie mysql
#// ssl spdy config nginx http 2.0? 
#// letsencrypt integratie
#// domeinnaam opvraag externe url?
#// geen root login

echo ""
echo ""
echo ""
echo "==========================================================="
echo "Mysql password: $MYSQL_PASSWORD"
print "Ip is: "
ifconfig eth0 | grep inet | awk '{ print $2 }'