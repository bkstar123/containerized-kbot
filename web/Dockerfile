##
 # tuanha
 # 18-Mar-2021
#
# Stage 1
FROM composer:1.10.20 AS composer

# Stage 2
FROM ubuntu:20.04
EXPOSE 80
EXPOSE 443
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apt-get update -y && \
    apt-get install cron -y && \
    apt-get install software-properties-common -y && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get install -y php7.3 php7.3-dev php7.3-mysql php7.3-json php7.3-gd php7.3-ldap php7.3-mbstring libmcrypt-dev php-pear php7.3-soap php7.3-cli php7.3-curl php7.3-zip php7.3-intl php7.3-xml
COPY ./sites-available/kbot.conf /etc/apache2/sites-available/kbot.conf
COPY ./conf-available/charset.conf /etc/apache2/conf-available/charset.conf  
COPY ./conf-available/security.conf /etc/apache2/conf-available/security.conf
RUN a2ensite kbot.conf && \
    a2dissite 000-default.conf && \
    a2enmod rewrite && \
    a2enmod headers && \
    mkdir -p /var/www/html && \
    cd /var/www/html && \
    apt-get -y install git && \
    git clone https://bkstar123@bitbucket.org/bkstar123/kbot.git && \
    cd kbot && composer install && cp .env.example .env && php artisan key:generate && \
    . /etc/apache2/envvars && \
    chown $APACHE_RUN_USER:$APACHE_RUN_GROUP -R . && \
    apt-get install -y nodejs npm && \
    npm install && npm run production && npm prune --production
# Schedule a cronjob for the Laravel scheduler
RUN echo "* * * * * cd /var/www/html/kbot && php artisan schedule:run >> /dev/null 2>&1" > /tmp/cron_list && \
    crontab /tmp/cron_list && \
    rm -rf /tmp/cron_list
WORKDIR /var/www/html/kbot
# container mounting points for apache2 & application logs
VOLUME /var/log/apache2 /var/www/html/kbot/storage/logs
ENTRYPOINT . /etc/apache2/envvars && /usr/sbin/apache2 -k start -DFOREGROUND