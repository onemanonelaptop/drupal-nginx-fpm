#!/bin/bash

# set -e

php -v

echo "Setup openrc ..." && openrc && touch /run/openrc/softlevel

# Add the keys and set permissions
mkdir /root/.ssh
ssh-keyscan -t rsa vs-ssh.visualstudio.com > ~/.ssh/known_hosts
echo "$ID_RSA" > /root/.ssh/id_rsa
echo "$ID_RSA_PUB" > /root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa.pub

# Set the git repo
GIT_REPO=${GIT_REPO:-https://github.com/azureappserviceoss/drupalcms-azure}
echo "Git repo: $GIT_REPO";
# Track the master branch by default.
GIT_BRANCH=${GIT_BRANCH:-master}
echo "Git repo: $GIT_BRANCH";

echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
echo "REPO: "$GIT_REPO
echo "BRANCH: "$GIT_BRANCH
echo "INFO: ++++++++++++++++++++++++++++++++++++++++++++++++++:"
echo "INFO: Clone from "$GIT_REPO
git clone $GIT_REPO /var/www/html
cd /var/www/html

echo "INFO: Checkout to "$GIT_BRANCH
git fetch origin
git branch --track $GIT_BRANCH origin/$GIT_BRANCH && git checkout $GIT_BRANCH

if [ "$COMPOSER_DEPLOY" == "true" ];then
    echo "INFO: Performing a composer install."
    cd /var/www/html
    composer install
fi

# Create the files directory if it does not exist.
if test ! -e /home/site/files; then
    echo "Creating files directory..."
    mkdir /home/site/files
    echo "Changing files directory permissions..."
    chmod  777 /home/site/files
fi
# Create the files symlink if it does not exist.
if ! [ -L /var/www/html/files ] ; then
  echo "Symlinking file directory..."
  ln -s /home/site/files /var/www/html/web/sites/default/files
fi

# Create the private_files directory if it does not exist.
if test ! -e /home/site/private_files; then
    echo "Creating private_files directory..."
    mkdir /home/site/private_files
    echo "Changing private_files directory permissions..."
    chmod  777 /home/site/private_files
fi
# Create the private_files symlink if it does not exist.
if ! [ -L /var/www/html/private_files ] ; then
  echo "Symlinking private_files directory..."
  ln -s /home/site/private_files /var/www/html/private_files
fi

# Copy htaccess to private files directory.
if test ! -e /home/site/private_files/.htaccess; then
  echo "Copying htaccess to private files directory"
  cp /var/www/html/web/private.htaccess /home/site/private_files/.htaccess
fi


# Create the temp_files directory if it does not exist.
if test ! -e /home/site/temp_files; then
    echo "Creating temp_files directory..."
    mkdir /home/site/temp_files
    echo "Changing temp_files directory permissions..."
    chmod  777 /home/site/temp_files
fi
# Create the temp_files symlink if it does not exist.
if ! [ -L /var/www/html/temp_files ] ; then
  echo "Symlinking temp_files directory..."
  ln -s /home/site/temp_files /var/www/html/temp_files
fi

# Remove any settings file added by the scaffolding plugin
if test -e /var/www/html/web/sites/default/settings.php; then
  echo "Removing settings.php..."
  rm /var/www/html/web/sites/default/settings.php
fi

# Symlink the settings file
ln -s /var/www/html/web/sites/default/$AZURE_SERVER_TYPE.azure.settings.php /var/www/html/web/sites/default/settings.php

echo "INFO: creating /run/php/php8.1-fpm.sock ..."
test -e /run/php/php8.1-fpm.sock && rm -f /run/php/php8.1-fpm.sock
mkdir -p /run/php
touch /run/php/php8.1-fpm.sock
chown www-data:www-data /run/php/php8.1-fpm.sock
chmod 777 /run/php/php8.1-fpm.sock


echo "Starting SSH ...."
service ssh start

echo "Starting php-fpm ..."
service php8.1-fpm start
chmod 777 /run/php/php8.1-fpm.sock

echo "starting memcached"
service memcached start


echo "Setting up cron jobs ...."
crontab -l > mycron
echo "PATH=/usr/local/bin:/usr/bin" >> mycron
echo "*/1 * * * * drush --root=/var/www/html/web --quiet core-cron --yes" >> mycron
echo >> mycron
echo >> mycron
crontab mycron
rm mycron
service cron start

freshclam
service clamav-daemon start
service clamav-freshclam start

echo "Starting Nginx ..."
mkdir -p /home/LogFiles/nginx
if test ! -e /home/LogFiles/nginx/error.log; then 
    touch /home/LogFiles/nginx/error.log
fi
/usr/sbin/nginx -g "daemon off;"
#/usr/sbin/nginx


