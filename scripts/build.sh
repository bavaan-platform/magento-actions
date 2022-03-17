#!/usr/bin/env bash

PROJECT_PATH="$(pwd)"

echo "currently in $PROJECT_PATH"

cd "$PROJECT_PATH/magento"

/usr/local/bin/composer install --dry-run --no-dev --no-progress &> /dev/null

COMPOSER_COMPATIBILITY=$?

echo "Composer compatibility: $COMPOSER_COMPATIBILITY"


set -e

if [ $COMPOSER_COMPATIBILITY = 0 ]
then
	/usr/local/bin/composer install --no-dev --no-progress
else
  echo "using composer v1"
  /usr/local/bin/composer self-update --1
	/usr/local/bin/composer install --no-dev --no-progress
fi


chmod +x bin/magento

#mysqladmin -h mysql -u root -pmagento status
## fix magento error: connection default is not defined
echo "<?php  return ['db' => [ 'table_prefix' => '', 'connection' => [ 'default' => [ 'host' => 'mysql', 'dbname' => 'magento', 'username' => 'root', 'password' => 'magento', 'model' => 'mysql4', 'engine' => 'innodb', 'initStatements' => 'SET NAMES utf8;', 'active' => '1' ] ]]];" > app/etc/env.php
## end fix ##



if [ -n "$INPUT_DISABLE_MODULES"  ]
then
  echo "These modules will be discarded during install process $INPUT_DISABLE_MODULES"
  [ -f app/etc/config.php ] && cp app/etc/config.php app/etc/config.php.orig
fi

if [ $INPUT_ELASTICSUITE = 1 ]
then
  bin/magento setup:install --admin-firstname="local" --admin-lastname="local" --admin-email="local@local.com" --admin-user="local" --admin-password="local123" --base-url="http://magento.build/" --backend-frontname="admin" --db-host="mysql" --db-name="magento" --db-user="root" --db-password="magento" --use-secure=0 --use-rewrites=1 --use-secure-admin=0 --session-save="db" --currency="EUR" --language="en_US" --timezone="Europe/Rome" --cleanup-database --skip-db-validation --es-hosts="elasticsearch:9200" --es-user="" --es-pass="" --disable-modules="$INPUT_DISABLE_MODULES"
else
  if [ $INPUT_ELASTICSEARCH = 1 ]
  then
    bin/magento setup:install --admin-firstname="local" --admin-lastname="local" --admin-email="local@local.com" --admin-user="local" --admin-password="local123" --base-url="http://magento.build/" --backend-frontname="admin" --db-host="mysql" --db-name="magento" --db-user="root" --db-password="magento" --use-secure=0 --use-rewrites=1 --use-secure-admin=0 --session-save="db" --currency="EUR" --language="en_US" --timezone="Europe/Rome" --cleanup-database --skip-db-validation --elasticsearch-host="elasticsearch" --elasticsearch-port=9200 --disable-modules="$INPUT_DISABLE_MODULES"
  else
    bin/magento setup:install --admin-firstname="local" --admin-lastname="local" --admin-email="local@local.com" --admin-user="local" --admin-password="local123" --base-url="http://magento.build/" --backend-frontname="admin" --db-host="mysql" --db-name="magento" --db-user="root" --db-password="magento" --use-secure=0 --use-rewrites=1 --use-secure-admin=0 --session-save="db" --currency="EUR" --language="en_US" --timezone="Europe/Rome" --cleanup-database --skip-db-validation --disable-modules="$INPUT_DISABLE_MODULES"
  fi
fi

#--key=magento \


## the switch to production will build static content for all languages declared in config.php
bin/magento deploy:mode:set production

#or

#bin/magento setup:di:compile
#bin/magento deploy:mode:set --skip-compilation production
#bin/magento setup:static-content:deploy
#bin/magento setup:static-content:deploy en_US  -a adminhtml
#bin/magento setup:static-content:deploy fr_FR -f -s standard -a adminhtml
#bin/magento setup:static-content:deploy fr_FR -f -s standard  -t Creativestyle/theme-creativeshop

#composer dump-autoload -o


if [ -n "$INPUT_DISABLE_MODULES"  ]
then
  [ -f app/etc/config.php ] && mv app/etc/config.php.orig app/etc/config.php
fi
rm app/etc/env.php
