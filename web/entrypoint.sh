#!/bin/sh

# Schedule a cronjob for the Laravel scheduler
echo "* * * * * cd /var/www/html/kbot && php artisan schedule:run >> /dev/null 2>&1" > /tmp/cron_list && \
crontab /tmp/cron_list && \
rm -rf /tmp/cron_list

# Start cron service
service cron start

# Start main process
. /etc/apache2/envvars && /usr/sbin/apache2 -k start -DFOREGROUND