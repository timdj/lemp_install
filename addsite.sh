#!/bin/bash
if [ -z $1 ]
then
  exit $E_MISSING_POS_PARAM
fi
DOMAIN="$1"
/opt/letsencrypt/letsencrypt-auto certonly --email info@timdejong.nl --text --agree-tos -a webroot --webroot-path /var/www/letsencrypt --renew-by-default -d ${DOMAIN}
if [ $? -ne 0 ]
 then
        ERRORLOG=`tail /var/log/letsencrypt/letsencrypt.log`
	echo
	echo
	echo "Domain could not be verified, make sure dns is already set and Nginx is running"
	exit
 else
	cat >> "/etc/cron.monthly/letsencrypt_$DOMAIN.sh" <<EOL
#!/bin/sh
/opt/letsencrypt/letsencrypt-auto certonly --email info@timdejong.nl --text --agree-tos -a webroot --webroot-path /var/www/letsencrypt --renew-by-default -d $DOMAIN
/etc/init.d/nginx reload
EOL
	
	chmod +x /etc/cron.monthly/letsencrypt_$DOMAIN.sh

	sed -e "s/__DOMAIN_NAME__/${DOMAIN}/g" /etc/nginx/default_nginx_site.example > "/etc/nginx/conf.d/${DOMAIN}.conf"
	mkdir "/var/www/$DOMAIN"

	/etc/init.d/nginx restart
fi

