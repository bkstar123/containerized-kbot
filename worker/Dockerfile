##
 # tuanha
 # 27-Mar-2021
#
# Stage 1
FROM composer:1.10.20 AS composer

# Stage 2
FROM ubuntu:20.04
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apt-get -y update && apt-get -y install supervisor && \
    mkdir -p /tmp/supervisord
COPY ./supervisor/conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./supervisor/conf.d/kbot-worker.conf /etc/supervisor/conf.d/kbot-worker.conf
RUN apt-get install software-properties-common -y && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get install -y php7.3 php7.3-dev php7.3-mysql php7.3-json php7.3-gd php7.3-ldap php7.3-mbstring libmcrypt-dev php-pear php7.3-soap php7.3-cli php7.3-curl php7.3-zip php7.3-intl php7.3-xml && \
    apt-get -y install git
RUN mkdir -p /var/www/html && cd /var/www/html && \
    git clone https://bkstar123@bitbucket.org/bkstar123/kbot.git && \
    cd kbot && composer install && cp .env.example .env && php artisan key:generate
WORKDIR /var/www/html/kbot
# Container mounting point for logs
VOLUME /tmp/supervisord
ENTRYPOINT ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]