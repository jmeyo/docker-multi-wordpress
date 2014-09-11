#!/bin/bash

function setup_wordpress() {
    if [ ! -f ${instance_path}/wp-config.php ]; then
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    WORDPRESS_DB_NAME="wordpress_${wordpress_appname}"
    WORDPRESS_DB_USER="wp_${wordpress_appname}"
    WORDPRESS_DB_PASSWORD=`pwgen -c -n -1 12`

    sed -e "s/database_name_here/$WORDPRESS_DB_NAME/
    s/username_here/$WORDPRESS_DB_USER/
    s/password_here/$WORDPRESS_DB_PASSWORD/
    s/localhost/$MYSQL_HOST/
    s/define('WPLANG', '');/define('WPLANG', '{$wordpress_lang}');/
    /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" ${instance_path}/wp-config-sample.php > ${instance_path}/wp-config.php


    # Download nginx helper plugin
    curl -O `curl -i -s http://wordpress.org/plugins/nginx-helper/ | egrep -o "http://downloads.wordpress.org/plugin/[^']+"`
    unzip -o nginx-helper.*.zip -d ${instance_path}/wp-content/plugins
    chown -R www-data:www-data ${instance_path}/wp-content/plugins/nginx-helper

    # Activate nginx plugin and set up pretty permalink structure once logged in
    cat << ENDL >> ${instance_path}/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$wp_rewrite->set_permalink_structure( '/%postname%/' );
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '${instance_path}/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL

    chown www-data:www-data ${instance_path}/wp-config.php

    echo "Create Database"
    mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -e "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME;CREATE DATABASE $WORDPRESS_DB_NAME;"
    echo "Add user $WORDPRESS_DB_USER"
    mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO '$WORDPRESS_DB_USER'@'%' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'; FLUSH PRIVILEGES;"
    fi
    #This is so the passwords show up in logs.
    echo "Wordpress installed for ${wordpress_appname}"
    echo "- Wordpress User created: $WORDPRESS_DB_USER"
    echo "- Mysql Database created: $WORDPRESS_DB_NAME"
    echo "- Wordpress User password: $WORDPRESS_DB_PASSWORD"
}

function setup_nginx() {
    cp /root/nginx-site.conf /etc/nginx/sites-available/${instance}
    sed -i -e 's#__instance_name__#'"$instance_name"'#' -e 's#__instance_path__#'"$instance_path"'#' -e 's#__wordpress_appname__#'"$wordpress_appname"'#' /etc/nginx/sites-available/${instance}
    ln -s /etc/nginx/sites-available/${instance} /etc/nginx/sites-enabled/
}

for instance in `ls /root/wordpress-instances`; do
    source /root/wordpress-instances/${instance}

    instance_name=${instance/.conf/}
    instance_path=/usr/share/nginx/${wordpress_appname}
    mkdir ${instance_path}
    cp -R /usr/share/nginx/wordpress/* ${instance_path}
    # copy wordpress l10n
    cp -R /root/wordpress-languages ${instance_path}/wp-content/languages/

    setup_wordpress
    setup_nginx
done

# add correct rigths in order to choose language
chown -R www-data:www-data /usr/share/nginx/
service nginx restart
