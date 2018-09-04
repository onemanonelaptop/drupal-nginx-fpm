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

# Set the git repo, we should have an s8080 version for a default
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
if [ "$GIT_BRANCH" != "master" ];then
    echo "INFO: Checkout to "$GIT_BRANCH
    git fetch origin
    git branch --track $GIT_BRANCH origin/$GIT_BRANCH && git checkout $GIT_BRANCH
fi

# Symlink the files driectory to the azure blob storage location.
ln -s /home/site/files /var/www/html/web/sites/default/files
chmod -R 777 /var/www/html/web/sites/default/files


mkdir /home/site/private_files
chmod -R 777 /home/site/private_files
ln -s /home/site/private_files /var/www/html/private_files
chmod -R 777 /var/www/html/private_files
cp /var/www/html/web/private.htaccess /home/site/private_files/.htaccess

mkdir /home/site/temp_files
chmod -R 777 /home/site/temp_files
ln -s /home/site/temp_files /var/www/html/temp_files
chmod -R 777 /var/www/html/temp_files

# Symlink the settings file.
if [ "$AZURE_SERVER_TYPE" == "staging" ];then
    ln -s /var/www/html/web/sites/default/staging.azure.settings.php /var/www/html/web/sites/default/settings.php
fi
if [ "$AZURE_SERVER_TYPE" == "live" ];then
    ln -s /var/www/html/web/sites/default/live.azure.settings.php /var/www/html/web/sites/default/settings.php
fi



echo "INFO: creating /run/php/php7.2-fpm.sock ..."
test -e /run/php/php7.2-fpm.sock && rm -f /run/php/php7.2-fpm.sock
mkdir -p /run/php
touch /run/php/php7.2-fpm.sock
chown www-data:www-data /run/php/php7.2-fpm.sock
chmod 777 /run/php/php7.2-fpm.sock


echo "Starting SSH ...."
service ssh start

echo "Starting php-fpm ..."
service php7.2-fpm start
chmod 777 /run/php/php7.2-fpm.sock

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


