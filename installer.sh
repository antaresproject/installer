#!/usr/bin/env bash
# Defines colors
default_color='\e[39m'
red_color='\e[31m'
green_color='\e[32m'
yellow_color='\e[33m'
bold_font='\033[1m'
underline_font='\033[4m'


INSTALLER_URL='https://github.com/antaresproject/installer/archive/master.zip'
HOST='';
LOGFILE="/var/www/install-log.log"
source functions.sh

download_package()
{
    # Downloads the archive
    $(cd /var/www && curl -o master.zip -LOk --request GET ''$INSTALLER_URL'');

    if [ ! -f /var/www/master.zip ]; then
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

apt-get update &>$LOGFILE

# Declare an array with required packages
declare -a requiredPackages=(
    'jq'
    'dialog'
    'ssh'
    'curl'
    'unzip'
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
        apt-get -y install "$package" &>$LOGFILE
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
unzip -o /var/www/master.zip -d /var/www > /dev/null 2>&1

# Getting server hostname
get_hostname

# run.sh
sudo bash /var/www/installer-master/run.sh

# install.sh
sudo bash /var/www/installer-master/install.sh
