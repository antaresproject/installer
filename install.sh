#!/usr/bin/env bash

# Defines colors
default_color='\e[39m'
red_color='\e[31m'
green_color='\e[32m'
yellow_color='\e[33m'
bold_font='\033[1m'
underline_font='\033[4m'
PACKAGE_URL='https://github.com/antaresproject/project.git'
VERSION='0.9.2';
TOKEN='';
CLIENT='';
ERROR='';
MSG='';
INSTALL_DIR='/var/www/antares';
ANTARES_DIR='/var/www/html'
HOST='';

# Function Definitions

get_hostname ()
{
  HOST=`hostname -f 2>/dev/null`
  if [ "$host" = "" ]; then
    HOST=`hostname 2>/dev/null`
    if [ "$host" = "" ]; then
      HOST=$HOSTNAME
      if [ "$host" = "" ]; then
        HOST=$(curl -s icanhazip.com)
      fi
    fi
  fi

  if [ "$HOST" = "" -o "$HOST" = "(none)" ]; then
    echo "Unable to determine the hostname of your system!"
    echo
    echo "Please consult the documentation for your system. The files you need "
    echo "to modify to do this vary between Linux distribution and version."
    echo
    exit 1
  fi
}

download_package()
{
    echo -e "$yellow_color";
    echo "Please wait, package is downloading...";
    echo -e "$default_color";    
    git clone "$PACKAGE_URL" -b "$VERSION" "$INSTALL_DIR"    
}

composer_install()
{
    echo -e "$yellow_color";
    echo "Please wait, running composer install...";
    echo -e "$default_color";
    cd $INSTALL_DIR && composer install
}

configure_database()
{
    # Define the dialog exit status codes
    : ${DIALOG_OK=0}
    : ${DIALOG_CANCEL=1}
    : ${DIALOG_ESC=255}

    DB_HOST=$1;
    DB_USERNAME=$2;
    DB_PASSWORD=$3;
    DB_NAME=$4;
    DB_PREFIX=$5;
    ERROR=$6;

    dialog --backtitle "Antares Project Configuration" --title "Database Configuration" \
    --form "- Use [tab] to switch between buttons\n
- Use [up] [down] to select input field\n
- If you used the configuration script, the full access database username is root\n
- That if the database with provided name won't exists yet, it will automatically be created\n
- It is highly recommended to use the separated database for the Antares Project \n \n
$ERROR" 20 80 0 \
    "Hostname:" 1 1 "$DB_HOST" 1 15 50 0 \
    "Username:" 2 1 "$DB_USERNAME"    2 15 50 0 \
    "Password:" 3 1 "$DB_PASSWORD"    3 15 50 0 \
    "Database:" 4 1 "$DB_NAME"        4 15 50 0 \
    2>/tmp/form.$$

    # Get the exit status
    return_value=$?

    IFS=$'\n' read -d '' -r -a lines < /tmp/form.$$

    DB_HOST="${lines[0]}";
    DB_USERNAME="${lines[1]}";
    DB_PASSWORD="${lines[2]}";
    DB_NAME="${lines[3]}";

    # Act on it
    case $return_value in $DIALOG_OK)
        # Check database connection
        while ! mysql --host=$DB_HOST --user=$DB_USERNAME --password=$DB_PASSWORD -e ";" ; do
               configure_database "$DB_HOST" "$DB_USERNAME" "$DB_PASSWORD" "$DB_NAME" 'Error occured! Could not connect to the database...'
        done

        # Generate random database name
        if [ -z "$DB_NAME" ]
            then
                SUFFIX=$(random-string 8);
                DB_NAME='antares_'$SUFFIX;
        fi

        # Check database name
        RESULT=$(mysqlshow --host=$DB_HOST --user=$DB_USERNAME --password=$DB_PASSWORD $DB_NAME | grep -v Wildcard | grep -ow $DB_NAME);

        if [ "$RESULT" == "$DB_NAME" ]; then
            configure_database "$DB_HOST" "$DB_USERNAME" "$DB_PASSWORD" "$DB_NAME" 'Error occured! Database '$DB_NAME' already exists. Please choose another database or leave empty.'
        fi
        ;;
      $DIALOG_CANCEL)
            echo -e "$red_color";
            echo "ERROR OCCURED!"
            echo "-----------------------------------"
            echo "Database has not been configured...";
            echo -e "$default_color";
            exit
            ;;
      $DIALOG_ESC)
            echo -e "$red_color";
            echo "ERROR OCCURED!"
            echo "-----------------------------------"
            echo "Database has not been configured...";
            echo -e "$default_color";
            exit
            ;;
    esac
}

create_database()
{
    # Everything is good
    echo -e "$yellow_color";
    echo "Configure Antares database...";
    echo -e "$default_color";

    mysql --host=$DB_HOST --user=$DB_USERNAME --password=$DB_PASSWORD -e 'CREATE DATABASE '$DB_NAME'';
    touch "$INSTALL_DIR"/app/config/database.php
    sed -e 's/{{dbHost}}/'$DB_HOST'/g' -e 's/{{dbName}}/'$DB_NAME'/g' -e 's/{{dbUser}}/'$DB_USERNAME'/g' -e 's/{{dbPassword}}/'$DB_PASSWORD'/g' -e "$INSTALL_DIR"/storage/database.php.example > "$INSTALL_DIR"/app/config/database.php

    echo -e "$green_color";
    echo "Database has been successfully configured...";
    echo -e "$default_color";
}

random-string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

verify_dependencies()
{
    # Permissions
    chmod 777 "$INSTALL_DIR"/public
    chmod -R 777 "$INSTALL_DIR"/storage
    chmod -R 777 "$INSTALL_DIR"/bootstrap
    

    
    chown -R www-data:www-data "$INSTALL_DIR"/public
    chown -R www-data:www-data "$INSTALL_DIR"/storage
    chown -R www-data:www-data "$INSTALL_DIR"/bootstrap
    chown -R www-data:www-data "$INSTALL_DIR"/builds
    chown -R www-data:www-data "$INSTALL_DIR"/build


    # Clear the compiled classes
    php "$INSTALL_DIR"/artisan clear-compiled

    # Optimizing the autoloader
    php "$INSTALL_DIR"/console optimize

    # Clear cache
    php "$INSTALL_DIR"/console cache:clear
}

# Exit script, if not run from sudo
if [ "$EUID" -ne 0 ]
  then
  echo -e "$red_color";
  echo "Please run as root...";
  echo -e "$default_color";
  exit;
fi;



echo -e "$green_color";
echo "#################################################################";
echo "#                  Download Antares Package                     #";
echo "#################################################################";
echo -e "$default_color";

download_package


echo -e "$green_color";
echo "#################################################################";
echo "#                       Composer install                        #";
echo "#################################################################";
echo -e "$default_color";

#composer_install

configure_database

create_database

verify_dependencies

get_hostname


echo -e "$green_color";
echo "#################################################################";
echo -e "Antares Project has been successfully installed!" >&2;
echo -e "Please now open your browser and point to: " >&2;
echo -e "http://YOUR_IP_ADDRESS/install";
echo "#################################################################";
echo -e "$default_color";
