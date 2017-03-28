#!/usr/bin/env bash
# Defines colors
default_color='\e[39m'
red_color='\e[31m'
green_color='\e[32m'
yellow_color='\e[33m'
bold_font='\033[1m'
underline_font='\033[4m'


INSTALLER_URL='https://github.com/antaresproject/installer/archive/master.zip'
ANTARES_VERSION='master'
LICENSE_STATUS='';
TOKEN='';
CLIENT='';
ERROR='';
MSG='';
LICENSE_KEY='';
URL='';
HOST='';

# Exit script, if not run from sudo
if [ "$EUID" -ne 0 ]
  then
  echo -e "$red_color";
  echo "Please run as root...";
  echo -e "$default_color";
  exit;
fi;

get_hostname()
{
  echo -n "Getting the hostname of this machine..."

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

  echo -n "Found hostname: $HOST"
}




download_package()
{
    # Make the directory
    mkdir -p /var/www

    # Downloads the archive
    $(cd /var/www && curl -o master.zip -LOk --request GET ''$INSTALLER_URL'');

    if [ ! -f /var/www/html/master.zip ]; then
            echo -e "$red_color";
                echo "ERROR OCCURED!"
                echo "-----------------------------------"
                echo "Cannot download installer package...";
                echo -e "$default_color";
                exit;
        fi
}





echo -e "$green_color";
echo "#################################################################";
echo "#                  Update APT Repository                        #";
echo "#################################################################";
echo -e "$default_color";

apt-get update

# Declare an array with required packages
declare -a requiredPackages=(
    'jq'
    'ssh'
    'curl'
    'unzip'
    'wget'    
);

echo -e "$green_color";
echo "#################################################################";
echo "#                  Installing required Packages                 #";
echo "#################################################################";
echo -e "$default_color";

for package in "${requiredPackages[@]}"
do
    if [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo -e "- $red_color Install package: $package $default_color";
        apt-get -y install "$package" >> /dev/null
    fi;
done



echo -e "$green_color";
echo "#################################################################";
echo "#                  Download Antares Package                     #";
echo "#################################################################";
echo -e "$default_color";

download_package

echo -e "$green_color";
echo "#################################################################";
echo "#                  Unpack Antares Package                      #";
echo "#################################################################";
echo -e "$default_color";

echo -e "$yellow_color";
echo "Please wait, package is unpacking...";
echo -e "$default_color";

# Unpack the files
unzip -o /var/www/html/master.zip -d /var/www/html/antares > /dev/null 2>&1

# Getting server hostname
get_hostname

# run.sh
sudo bash /var/www/html/antares/installer-master/run.sh

if [ -f "/etc/apache2/sites-available/antares.conf" ]
    then
        URL="http://YOUR_IP_ADDRESS/antares/install (http://$HOST/antares/install)";
    else
        URL="http://YOUR_IP_ADDRESS/install (http://$HOST/install)";
fi;


# install.sh
sudo bash /var/www/html/antares/installer-master/install.sh
