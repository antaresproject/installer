#!/usr/bin/env bash

# Os and architecture detection
OS=$(lsb_release -si)
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
VER=$(lsb_release -sr)

# Function Definitions

echoerror() { echo "$@" 1>&2; }

verifycommand()
{
    if [ $? -eq 0 ]
    then
        echo $1;
    else
        echoerror $2;
        exit 2;
    fi
}

# Defines colors

default_color='\e[39m'
red_color='\e[31m'
green_color='\e[32m'
bold_font='\033[1m'
underline_font='\033[4m'

# Gets original user
original_username=`who am i | awk '{print $1}'`

original_homedir=$( getent passwd "$original_username" | cut -d: -f6 )

# Assign the composer location
composer_location='/usr/local/bin/composer'

# Assign the current dir to variable
current_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ $current_dir != "/var/www/html/antares/installer-master" ]]
then
    echo "$red_colorPlease place the installer files into the /var/www/html/antares/installer-master directory$default_color"
    exit;
fi;

# Exit script, if not run from sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo -e "$green_color";
echo "#################################################################";
echo "#                  Update APT Repository                        #";
echo "#################################################################";
echo -e "$default_color";



echo -e "$green_color";
echo "#################################################################";
echo "#         Installing software-properties-common                 #";
echo "#################################################################";
echo -e "$default_color";

apt-get install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt-get update

echo -e "$green_color";
echo "#################################################################";
echo "#         Installing system environment                         #";
echo "#################################################################";
echo -e "$default_color";

# Declare an array with required packages
declare -a requiredPackages=(
    'curl'
    'git'
    'apache2'
    'wget'
    'git'
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
echo "#                  Installing required Packages                 #";
echo "#################################################################";
echo -e "$default_color";

if [ $(dpkg-query -W -f='${Status}' "mysql-server" 2>/dev/null | grep -c "ok installed") -eq 0 ];
   then
   echo -e "MySQL not found! Installing now. $red_color Please remember the password you'll provide while configuration! $default_color";
   sudo apt-get -y install mysql-server;
fi

for package in "${requiredPackages[@]}"
do
    if [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo -e "- $red_color Install package: $package $default_color";
        apt-get -y -f install "$package" >> /dev/null
    fi;
done

sudo service apache2 restart

# Install composer
echo -e "$green_color";
echo "#################################################################";
echo "#                     Installing composer                       #";
echo "#################################################################";
echo -e "$default_color";
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer


if [ ! -f "$original_homedir"/.ssh/authorized_keys ]
then
    mkdir -p "$original_homedir"/.ssh;
    touch "$original_homedir"/.ssh/authorized_keys;
fi;

# Virtual Host Generation
antares_default_site=true;

cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orginal;

# Make the Antares default site
cp -a /var/www/html/conf/samples/antares.apache.vhost.sample /etc/apache2/sites-available/000-default.conf

# Enable the PHP mcrypt extension
# php5enmod mcrypt

# Enable the Apache Rewrite module
a2enmod rewrite
a2enmod filter
a2enmod deflate
a2enmod alias
a2enmod headers
a2enmod mime
a2enmod env

# Reload the apache
service apache2 reload

echo -e "$green_color";
echo "#################################################################";
echo "#                 Generating the pair of the SSH Keys           #";
echo "#################################################################";
echo -e "$default_color";

mkdir -p "$current_dir"/public/install/temp/keys/

chown -R "$original_username":"$original_username" "$current_dir"/public/install/temp/keys

# Create the SSH key, -V "+1d"
sudo -u "$original_username" ssh-keygen -t rsa -N "" -f "$current_dir"/public/install/temp/keys/antares.key

# Append the key to authorized keys

options_string='from="10.0.0.?,localhost,127.0.0.1"';
generated_key=$(cat "$current_dir"/public/install/temp/keys/antares.key.pub);

sudo echo "$original_username" > "$current_dir"/public/install/temp/username

if [ ! -f "$original_homedir"/.ssh/authorized_keys ]
then
    mkdir -p "$original_homedir"/.ssh;
    touch "$original_homedir"/.ssh/authorized_keys;
fi;

authorized_keys_content=$(sudo -u "$original_username" cat "$original_homedir"/.ssh/authorized_keys);

if [ -z "$authorized_keys_content" ];
then
    sudo -u "$original_username" echo "$options_string $generated_key" > "$original_homedir"/.ssh/authorized_keys;
else
    if grep --quiet '$generated_key' "$original_homedir"/.ssh/authorized_keys; then
      echo -e "$red_color Key is already set, ommiting! $default_color"
    else
      sudo -u "$original_username" echo -e "$options_string $generated_key" >> "$original_homedir"/.ssh/authorized_keys;
    fi
fi;


chown -R "$original_username":"$original_username" "$current_dir"
chown -R www-data:www-data "$current_dir"/public/install/temp/keys

# Sets the proper permissions to the file
chmod 755 "$current_dir"/public/install/temp/keys/antares.key


exit;
