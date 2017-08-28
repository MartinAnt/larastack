#!/usr/bin/env bash

set -e

# ---------------------------------------------------------------------------- #
#                                                                              #
# Install Drupal 8 files.                                                      #
#                                                                              #
# Readme more: https://github.com/drupal-composer/drupal-project               #
#                                                                              #
# ---------------------------------------------------------------------------- #

WORKING_DIR="$(pwd)"

SCRIPT_PATH="$(dirname ${0})"
SCRIPT_PATH="$(cd ${SCRIPT_PATH} && pwd)"

PROJECT_ROOT="$(cd ${SCRIPT_PATH}/.. && pwd)"

hash docker 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "docker command not found."

  exit 1
fi

hash docker-compose 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "docker-compose command not found."

  exit 1
fi

php_container_exists() {
  local PROJECT_ROOT="${1}"

  echo "$(cd ${PROJECT_ROOT} && docker-compose -f docker-compose.yml ps php 2> /dev/null | grep _php_ | awk '{ print $1 }')"
}

php_container_running() {
  local CONTAINER="${1}"

  echo "$(docker exec ${CONTAINER} date 2> /dev/null)"
}

PHP_CONTAINER="$(php_container_exists ${PROJECT_ROOT})"

if [ -z "${PHP_CONTAINER}" ]; then
  read -p "PHP container could not be found. Would you like to start the containers? [Y/n]: " ANSWER

  if [ "${ANSWER}" == "n" ]; then
    exit
  fi

  cd "${PROJECT_ROOT}"

  docker-compose -f docker-compose.yml up -d

  PHP_CONTAINER="$(php_container_exists ${PROJECT_ROOT})"

  echo "crush: Waiting for PHP service to come up..."

  sleep 30
elif [ -z "$(php_container_running ${PHP_CONTAINER})" ]; then
  read -p "crush: PHP container is not running. Would you like to start the containers? [Y/n]: " ANSWER

  if [ "${ANSWER}" == "n" ]; then
    exit
  fi

  cd "${PROJECT_ROOT}"

  docker-compose -f docker-compose.yml up -d

  echo "crush: Waiting for PHP service to come up..."

  sleep 30
fi

docker exec -it "${PHP_CONTAINER}" bash -c "rm -rf /usr/local/apache2/htdocs/web"
docker exec -it "${PHP_CONTAINER}" bash -c "composer create-project drupal-composer/drupal-project:8.x-dev /usr/local/apache2/htdocs --stability dev --no-interaction"

cd "${WORKING_DIR}"
