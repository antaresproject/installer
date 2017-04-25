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

if [ ! -z $1 ] 
then 
    LOCATION=$1
else
    LOCATION=/var/www/html
fi
TEMP=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
LOGFILE="$TEMP/install-log.log"

download_package()
{
    # Downloads the archive
    $(cd "$TEMP" && curl --insecure -o master.zip -LOk --request GET ''$INSTALLER_URL'');

    if [ ! -f "$TEMP"/master.zip ]; then
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
echo "#                  Update APT Repository (1/11)                 #";
echo "#################################################################";
echo -e "$default_color";

apt-get update --allow-unauthenticated &>$LOGFILE

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
echo "#              Installing required Packages (2/11)              #";
echo "#################################################################";
echo -e "$default_color";

for package in "${requiredPackages[@]}"
do
    if [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo -e "- $red_color Install package: $package $default_color";
        apt-get -y install --allow-unauthenticated "$package" &>$LOGFILE
    fi;
done



echo -e "$green_color";
echo "#################################################################";
echo "#               Download Antares Package (3/11)                 #";
echo "#################################################################";
echo -e "$default_color";

download_package

echo -e "$green_color";
echo "#################################################################";
echo "#                Unpack Antares Package (4/11)                  #";
echo "#################################################################";
echo -e "$default_color";

echo -e "$yellow_color";
echo "Please wait, package is unpacking...";
echo -e "$default_color";


# Unpack the files
unzip -o "$TEMP"/master.zip -d "$TEMP" > /dev/null 2>&1

# run.sh
sudo bash $TEMP/installer-master/run.sh $LOCATION

# install.sh
sudo bash $TEMP/installer-master/install.sh $LOCATION

