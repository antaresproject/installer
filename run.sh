#!/usr/bin/env bash


if [ ! -z $1 ] 
then 
    LOCATION=$1
else
    LOCATION=/var/www/html
fi

# Assign the current dir to variable
current_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

TEMP=$current_dir
LOGFILE="$TEMP/install-log.log"


# Function Definitions

echoerror() { echo "$@" 1>&2; }


# Defines colors

default_color='\e[39m'
red_color='\e[31m'
green_color='\e[32m'
bold_font='\033[1m'
underline_font='\033[4m'

# Gets original user
original_username=`who am i | awk '{print $1}'`
original_homedir=$( getent passwd "$original_username" | cut -d: -f6 )


echo -e "$green_color";
echo "#################################################################";
echo "#         Installing software-properties-common (5/11)          #";
echo "#################################################################";
echo -e "$default_color";

sudo apt-get install software-properties-common -y --allow-unauthenticated &>>$LOGFILE
sudo add-apt-repository ppa:ondrej/php -y &>>$LOGFILE

echo -e "$green_color";
echo "#################################################################";
echo "#                Update APT Repository (6/11)                   #";
echo "#################################################################";
echo -e "$default_color";

sudo apt-get update --allow-unauthenticated &>>$LOGFILE

echo -e "$green_color";
echo "#################################################################";
echo "#             Installing System Environment (7/11)              #";
echo "#################################################################";
echo -e "$default_color";

# Declare an array with required packages
declare -a requiredPackages=(
    'curl'
    'git'
    'apache2'
    'libapache2-mod-php7.1'
    'php7.1'
    'php7.1-bz2'
    'php7.1-mcrypt'
    'php7.1-curl'
    'php7.1-json'
    'php7.1-fileinfo'
    'php7.1-mbstring'
    'php7.1-gd'
    'php7.1-bcmath'
    'php7.1-xml'
    'php7.1-dom'
    'php7.1-pdo'
    'php7.1-zip'
    'php7.1-gettext'
    'php7.1-sqlite'
    'php7.1-tokenizer'
    'php7.1-mysql'
    'zip'
    'unzip' 
);

echo -e "$green_color";
echo "#################################################################";
echo "#               Installing Required Packages (8/11)             #";
echo "#################################################################";
echo -e "$default_color";

if [ $(dpkg-query -W -f='${Status}' "mysql-server" 2>/dev/null | grep -c "ok installed") -eq 0 ];
   then
   echo -e "MySQL not found! Installing now. $red_color Please remember the password you'll provide while configuration! $default_color";
   sudo apt-get -y install --allow-unauthenticated mysql-server;
fi

for package in "${requiredPackages[@]}"
do
    if [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo -e "- $red_color Install package: $package $default_color";
        sudo apt-get -y -f --allow-unauthenticated install "$package" &>>$LOGFILE
    fi;
done


sudo service apache2 restart &>>$LOGFILE 

# Install composer
echo -e "$green_color";
echo "#################################################################";
echo "#                  Installing Composer (9/11)                   #";
echo "#################################################################";
echo -e "$default_color";
sudo  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer &>>$LOGFILE



# Virtual Host Generation
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orginal;
# Make the Antares default site

echo "<VirtualHost *:80>
        ServerAdmin youremail@domain.net
        DocumentRoot $LOCATION
        SetEnv DEVELOPMENT_MODE production
        <Directory $LOCATION>
                Require all granted
                AllowOverride All
        </Directory>
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf


# Enable the Apache modules
a2enmod rewrite  &>>$LOGFILE
a2enmod filter  &>>$LOGFILE
a2enmod deflate  &>>$LOGFILE
a2enmod alias  &>>$LOGFILE
a2enmod headers  &>>$LOGFILE
a2enmod mime  &>>$LOGFILE
a2enmod env  &>>$LOGFILE

# Reload the apache
sudo service apache2 reload &>>$LOGFILE

chown -R "$original_username":"$original_username" "$current_dir"

exit;
