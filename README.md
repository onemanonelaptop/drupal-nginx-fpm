# Drupal based Docker container for Azure Web Apps

This project should provide a re-usable container to host your Drupal site on the Azure Web Apps for Containers service.

## Usage

Specify this container image in the container settings page of your app service.

## Setting up GIT deployment

Add the following Applications settings to your APP service

COMPOSER_DEPLOY= true/false     for a composer install
CONFIG_MANAGED = true/false   for sh scripts/update.sh
GIT_BRANCH = Your branch name e.g. develop
GIT_REPO = Your remote repositories ssh url.
ID_RSA = Your RSA Private Key
ID_RSA_PUB = Your RSA Public Key

WEBSITES_CONTAINER_START_TIME_LIMIT = 3600
WEBSITES_ENABLE_APP_SERVICE_STORAGE = true
WEBSITES_PORT = 443

AZURE_SERVER_TYPE = live/staging



Notes:
In order for secure cookies to be set you will need to set the trusted proxies

e.g.
$settings['reverse_proxy'] = TRUE;
$settings['reverse_proxy_addresses'] = ['122.28.0.1'];


To test a docker build:
docker build .

To tag and deploy
docker build -t s8080/drupal-nginx-fpm .
docker tag s8080/drupal-nginx-fpm SOMETHING.azurecr.io/drupal-nginx-fpm:VERSION
docker push SOMETHING.azurecr.io/drupal-nginx-fpm:VERSION


Ensure line endings are LF.


