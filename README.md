# Drupal based Docker container for Azure Web Apps

This project should provide a re-usable container to host your Drupal site on the Azure Web Apps for Containers service.

## Usage

Specify this container image in the container settings page of your app service.

## Setting up GIT deployment

Add the following Applications settings to your APP service

GIT_BRANCH = Your branch name e.g. develop
GIT_REPO = Your remote repositories ssh url.
ID_RSA = Your RSA Private Key
ID_RSA_PUB = Your RSA Public Key

WEBSITES_CONTAINER_START_TIME_LIMIT = 500
WEBSITES_ENABLE_APP_SERVICE_STORAGE = true