#!/bin/bash
#########################################################
#                                                       #
#   Name: Website Creator                               #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will create                #
#   automatically the folder, database and              #
#   virtualhost of a specified website                  #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Constants
WEBSITE="diegocastagna.com"
SCRIPTNAME="WEBSITE_CREATOR"
PREFIX="[$WEBSITE][$SCRIPTNAME]"
SITEPATH="/var/www"

# Variables
folderName="${1}"
dbName="${2}"
dbSitePass=$(openssl rand -base64 32)
subFolder="${3}"
vhPrefix=""

# Performing some checks
if [[ $EUID -ne 0 ]]; then
    echo "$PREFIX This script must be run as root or with sudo privileges"
    exit 1
fi
if [ $# -le 1 ]; then
    echo "Usage: ${0} FolderName DBName [SubFolder]"
    echo "If 'SubFolder' is empty 'www' will be used"
    exit 1
fi
if [ -z $subFolder ]; then
    # Using default www folder
    subFolder="www"
else
    vhPrefix+="$subFolder."
fi

# Performing some sanity checks before starting
echo "$PREFIX Performing some checks before starting.."
if [ -f "/etc/apache2/sites-available/$siteFolderName.conf" ]; then
    # Aborting because the virtualhost file already exists
    echo "$PREFIX The virtualhost file already exists, aborting.."
    exit 1
fi
if mysql -u root -e "use $dbName"; then
    echo "$PREFIX The database already exists, aborting.."
    exit 1
fi

# Folder
echo "$PREFIX Creating folders and setting up permissions.."
cd $SITEPATH
mkdir -p "$siteFolderName/$subFolder"
chown -R www-data:www-data "$siteFolderName"
chmod -R 775 "$siteFolderName"

# Virtualhost
echo "$PREFIX Creating and enabling website virtualhost.."
echo "<VirtualHost *:80>
    # Basic
    ServerAlias $subFolder.$siteFolderName
    ServerName $siteFolderName
    ServerAdmin webmaster@localhost
    DocumentRoot $SITEPATH/$siteFolderName/$subFolder

    # Extra Security
    php_admin_value open_basedir \"/tmp/:$SITEPATH/$siteFolderName/$subFolder/\"

    # Logs
    ErrorLog \${APACHE_LOG_DIR}/${vhPrefix}${siteFolderName}_error.log
    CustomLog \${APACHE_LOG_DIR}/${vhPrefix}${siteFolderName}_access.log combined

    # Dir
    <Directory \"$SITEPATH/$siteFolderName/$subFolder/\">
            Options -Indexes +SymLinksifOwnerMatch
            AllowOverride All
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/$vhPrefix$siteFolderName.conf
chmod 644 /etc/apache2/sites-available/$vhPrefix$siteFolderName.conf
a2ensite -q /etc/apache2/sites-available/$vhPrefix$siteFolderName.conf

# Database
echo "$PREFIX Creating database and user.."
mysql -u root <<_EOF_
CREATE DATABASE IF NOT EXIST ${dbName};
GRANT ALL PRIVILEGES ON ${dbName}.* TO ${dbName}@localhost identified by '${dbSitePass}';
FLUSH PRIVILEGES;
_EOF_

echo "$PREFIX Creating and Securing logs files.."
install -m 640 -o root -g adm /dev/null "/var/log/apache2/${vhPrefix}${siteFolderName}_error.log"
install -m 640 -o root -g adm /dev/null "/var/log/apache2/${vhPrefix}${siteFolderName}_access.log"

echo "$PREFIX Restarting Apache and Mysql.."
service apache2 restart
service mysql restart

echo -e "\n\nUser Password: '$dbSitePass'\n\n"
echo "$PREFIX Script finished!"
echo "$PREFIX Thank you for downloading this script from $WEBSITE"