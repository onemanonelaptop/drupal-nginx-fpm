FROM nginx
MAINTAINER OneManOneLaptop <rob@onemanonelaptop.com>
# ========
# ENV vars
# ========
# ssh
ENV SSH_PASSWD "root:Docker!"
#nginx
ENV NGINX_VERSION stable
ENV NGINX_LOG_DIR "/home/LogFiles/nginx"
#php
ENV PHP_HOME "/usr/local/etc/php"
ENV PHP_CONF_DIR $PHP_HOME
ENV PHP_CONF_FILE $PHP_CONF_DIR"/php.ini"

# mariadb
ENV MARIADB_DATA_DIR "/home/data/mysql"
ENV MARIADB_LOG_DIR "/home/LogFiles/mysql"

#Web Site Home
ENV HOME_SITE "/var/www/html/web"
# redis
ENV PHPREDIS_VERSION 3.1.2

ENV COMPOSER_DOWNLOAD_URL "https://getcomposer.org/installer"
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /home/.composer
ENV COMPOSER_VERSION "1.6.1"
ENV COMPOSER_SETUP_SHA 544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061

# Set the Drush version.
ENV DRUSH_LAUNCHER_VER="0.6.0" \
    DRUPAL_CONSOLE_LAUNCHER_VER="1.8.0"


# ssh
COPY sshd_config /etc/ssh/ 
# php
COPY php.ini /usr/local/etc/php/php.ini
COPY www.conf /usr/local/etc/php/conf.d/www.conf
# nginx
COPY nginx.conf /etc/nginx/nginx.conf

# ----------
# Essentials
# ----------
RUN set -ex \
    && essentials=" \
        ca-certificates \
        wget \
        gnupg \
    " \
    && apt-get update \
    && apt-get install -y -V --no-install-recommends $essentials \
    && rm -r /var/lib/apt/lists/*

# ----------
# Packages
# ----------
RUN set -ex \
    && apt-get update \
    && apt-get -y install ca-certificates apt-transport-https \
    && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
    && echo "deb https://packages.sury.org/php/ bullseye main" | tee /etc/apt/sources.list.d/php.list

# ----------
# PHP
# ----------
RUN set -ex \
    && phps=" \
        php8.1-common \
        php8.1-fpm \
        php-pear \
        php8.1-apcu \
        php8.1-gd \
        php8.1-dba \
        php8.1-mysql \
		php8.1-xml \
		php8.1-mbstring \
		php8.1-curl \
	" \
    && apt-get update \
	&& apt-get install -y -V --no-install-recommends $phps \
	&& rm -r /var/lib/apt/lists/*


RUN update-alternatives --set php /usr/bin/php8.1

# ----------
# SSH
# ----------
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef  install -y  --no-install-recommends openssh-server \
    && echo "$SSH_PASSWD" | chpasswd

# ----------
# ??? What is this?
# ----------
RUN set -ex \
	&& apt-get autoremove -y

# --------
# ~. tools
# --------
RUN set -ex \
  && apt-get install -y git vim curl wget bash zip unzip cron clamav clamav-daemon


# --------
# ~. Patching
# --------
RUN set -ex \
  && apt-get install -y zlib1g libexpat1 libxslt1.1 libtirpc3 libfreetype6 gzip libssl1.1 openssl libldap-2.4-2 dpkg liblzma5 libc-bin libc6 libgssapi-krb5-2 libkrb5-3 libk5crypto3 libkrb5support0 libxml2

# ----------
# COMPOSER
# ----------
RUN set -ex \
	&& php -r "readfile('https://getcomposer.org/installer');" > /tmp/composer-setup.php \
  	&& mkdir -p /composer/bin \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin/ --filename=composer  \
    && rm /tmp/composer-setup.php

# ----------
# DRUSH
# ----------
RUN set -ex; \
    composer global require drush/drush:^8.0; \
    drush_launcher_url="https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VER}/drush.phar"; \
    wget -O drush.phar "${drush_launcher_url}"; \
    chmod +x drush.phar; \
    mv drush.phar /usr/local/bin/drush;

# ----------
# Memcached
# ----------
RUN apt-get update \
    && sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d \
    && apt-get -y install memcached php-memcached netcat


RUN apt-get update \
  &&  apt-get install imagemagick -y \
  &&  sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/g' /etc/ImageMagick-6/policy.xml

# ----------
# Mariadb server required for drush.
# ----------
RUN set -ex \
    && apt-get install -y mariadb.server


# ----------
# Copy Files
# ----------
# ssh
COPY sshd_config /etc/ssh/
# php
COPY php.ini /etc/php/8.1/cli/php.ini
COPY php.ini /etc/php/8.1/fpm/conf.d/drupal-php.ini
COPY www.conf /etc/php/8.1/fpm/pool.d/www.conf
# nginx
COPY nginx.conf /etc/nginx/nginx.conf



# =====
# final
# =====
COPY init_container.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_container.sh
EXPOSE 2222 443 11211 3310
ENTRYPOINT ["init_container.sh"]
