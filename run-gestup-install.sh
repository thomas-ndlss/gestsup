#!/usr/bin/env bash
#curl -s https://gestsup.fr/install.deb12.sh | bash

clear
echo -e '\e[34m---------------------------------------------------\e[0m';
echo -e '\e[34m---------GESTSUP INSTALLATION DEBIAN 12------------\e[0m';
echo -e '\e[34m---------------------------------------------------\e[0m';
echo '';

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

#ip=`hostname -I | cut -f1 -d' '`
#ip="gestsup.railway.internal"
ip="0.0.0.0"

#check gestsup system user
if [ ! -d "/home/gestsup" ] 
then
    echo -e '\e[31mERROR : System user gestsup missing, create system user gestsup\e[0m'
    exit 9999
fi

#global var
current_date=`date '+%Y-%m-%d'`

echo -n "1 - System update : "
${SUDO} -i apt-get update -y &> /dev/null
${SUDO} -i apt-get upgrade -y &> /dev/null
${SUDO} -i apt-get dist-upgrade -y &> /dev/null
${SUDO} -i apt autoremove -y &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "2 - Install prerequisites "
echo -n "      > apache2 : "
${SUDO} -i apt install apache2 -y &> /dev/null
${SUDO} -i service apache2 start -y &> /dev/null
if [[ `systemctl is-active apache2` == "active" ]]
then    
    echo -e "\e[32mOK\e[0m"
else
    echo -e "\e[31mKO service not running\e[0m"
fi
echo -n "      > mariadb-server : "
${SUDO} -i apt install mariadb-server -y &> /dev/null
${SUDO} -i service mariadb start -y &> /dev/null
if [[ `systemctl is-active mariadb` == "active" ]]
then    
    echo -e "\e[32mOK\e[0m"
else
    echo -e "\e[31mKO service not running\e[0m"
fi
echo -n "      > unzip : "
${SUDO} -i apt install unzip -y &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > ntp : "
${SUDO} -i apt install ntp -y &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > curl : "
${SUDO} -i apt install curl -y &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > cron : "
${SUDO} -i apt install cron -y &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "3 - Install PHP "
echo -n "      > install PHP : "
${SUDO} -i apt install php libapache2-mod-php -y &> /dev/null
${SUDO} -i apt install php-{common,curl,gd,imap,intl,ldap,mbstring,mysql,xml,zip} -y &> /dev/null

echo -e "\e[32mOK\e[0m"
echo -n "      > current php version : "
php -r 'echo PHP_VERSION." ";'
echo -e "\e[32mOK\e[0m"

echo "4 - Create database user  "
${SUDO} -i /etc/init.d/mariadb start &> /dev/null
db_gestsup_password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
${SUDO} -i mariadb -e "DROP USER IF EXISTS 'gestsup'@'localhost';"
${SUDO} -i mariadb -e "CREATE USER 'gestsup'@'localhost' IDENTIFIED BY '$db_gestsup_password';"
${SUDO} -i mariadb -e "GRANT ALL PRIVILEGES ON *.* TO 'gestsup'@'localhost';"
${SUDO} -i mariadb -e "FLUSH PRIVILEGES;"

echo -n "      > database user : gestsup "
echo -e "\e[32mOK\e[0m"
echo -n "      > database password : $db_gestsup_password "
echo -e "\e[32mOK\e[0m"

echo "5 - Update PHP parameters "
echo -n "      > max_execution_time : 480 "
${SUDO} -i sed -i 's/max_execution_time = 30/max_execution_time = 480/g' /etc/php/8.2/apache2/php.ini &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > memory_limit : 512M "
${SUDO} -i sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.2/apache2/php.ini &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > upload_max_filesize : 8M "
${SUDO} -i sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 8M/g' /etc/php/8.2/apache2/php.ini &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > date.timezone : Europe/Paris "
${SUDO} -i sed -i 's/;date.timezone =/date.timezone = Europe\/Paris/g' /etc/php/8.2/apache2/php.ini &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "6 - Update MariaDB parameters "
total_ram_o=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_mb=$(expr $total_ram_o / 1024)
ram_to_configure_mb=$(expr $total_ram_mb / 4)
ram_to_configure_mb=$ram_to_configure_mb"M"
echo -n "      > skip-name-resolve "
${SUDO} -i sed -i "s/# this is only for embedded server/skip-name-resolve/g" /etc/mysql/mariadb.conf.d/50-server.cnf &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > innodb_buffer_pool_size : $ram_to_configure_mb "
${SUDO} -i sed -i "s/#innodb_buffer_pool_size = 8G/innodb_buffer_pool_size = $ram_to_configure_mb/g" /etc/mysql/mariadb.conf.d/50-server.cnf &> /dev/null
echo -e "\e[32mOK\e[0m"

echo -n "7 - Download GestSup : "
last_version=`curl -s https://gestsup.fr/lastest_version.php`
${SUDO} -i wget -P /var/www/html https://gestsup.fr/downloads/versions/current/version/gestsup_$last_version &> /dev/null
echo -n "gestsup_$last_version "
echo -e "\e[32mOK\e[0m"

echo -n "8 - Extract files : "
${SUDO} -i unzip -o /var/www/html/gestsup_$last_version -d /var/www/html &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "9 - Remove install files "
echo -n "      > gestsup_$last_version : "
if test -f "/var/www/html/gestsup_$last_version"; then
    ${SUDO} -i rm /var/www/html/gestsup_$last_version
fi
echo -e "\e[32mOK\e[0m"
echo -n "      > index.html : "
if test -f "/var/www/html/index.html"; then
    ${SUDO} -i  rm /var/www/html/index.html
fi
echo -e "\e[32mOK\e[0m"
echo -n "      > install directory : "
if test -f "/var/www/html/install/index.php"; then
    ${SUDO} -i  rm -R /var/www/html/install/
fi
echo -e "\e[32mOK\e[0m"

echo -n "10 - Create database : "
${SUDO} -i /etc/init.d/mariadb start &> /dev/null
${SUDO} -i mariadb -e "CREATE DATABASE IF NOT EXISTS bsup;"
echo -n 'bsup '
echo -e "\e[32mOK\e[0m"

echo -n "11 - Import database skeleton : "
${SUDO} -i mariadb  bsup < /var/www/html/_SQL/skeleton.sql  &> /dev/null
${SUDO} -i mariadb  bsup -e "UPDATE tparameters SET telemetry='1'"
${SUDO} -i mariadb  bsup -e "UPDATE tparameters SET user_password_policy='1'"
${SUDO} -i mariadb  bsup -e "UPDATE tparameters SET user_password_policy_min_lenght='8'"
${SUDO} -i mariadb  bsup -e "UPDATE tparameters SET server_url='http://$ip'"
${SUDO} -i mariadb  bsup -e "UPDATE tparameters SET server_date_install='$current_date'"
server_private_key=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
${SUDO} -i mariadb  bsup -e "UPDATE tparameters SET server_private_key='$server_private_key'"

echo -e "\e[32mOK\e[0m"

echo -n "12 - Update GestSup users passwords : "
admin_password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
admin_password_hash=`php -r "echo password_hash('$admin_password', PASSWORD_DEFAULT);"`
${SUDO} -i mariadb  bsup -e "UPDATE tusers SET password='$admin_password_hash', last_pwd_chg='$current_date'  WHERE login='admin'"

password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
password_hash=`php -r "echo password_hash('$password', PASSWORD_DEFAULT);"`
${SUDO} -i mariadb  bsup -e "UPDATE tusers SET password='$password_hash', last_pwd_chg='$current_date'  WHERE login='super'"

password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
password_hash=`php -r "echo password_hash('$password', PASSWORD_DEFAULT);"`
${SUDO} -i mariadb  bsup -e "UPDATE tusers SET password='$password_hash', last_pwd_chg='$current_date'  WHERE login='tech'"

password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
password_hash=`php -r "echo password_hash('$password', PASSWORD_DEFAULT);"`
${SUDO} -i mariadb  bsup -e "UPDATE tusers SET password='$password_hash', last_pwd_chg='$current_date'  WHERE login='poweruser'"

password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
password_hash=`php -r "echo password_hash('$password', PASSWORD_DEFAULT);"`
${SUDO} -i mariadb  bsup -e "UPDATE tusers SET password='$password_hash', last_pwd_chg='$current_date'  WHERE login='user'"

echo -e "\e[32mOK\e[0m"

echo -n "13 - Update connect file : "
${SUDO} -i sed -i 's/db_name=\x27/db_name=\x27bsup/g' /var/www/html/connect.php &> /dev/null
${SUDO} -i sed -i 's/user=\x27/user=\x27gestsup/g' /var/www/html/connect.php &> /dev/null
${SUDO} -i sed -i 's/password=\x27/password=\x27'$db_gestsup_password'/g' /var/www/html/connect.php &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "14 - Check lastest stable patchs : "
last_version=`curl -s https://gestsup.fr/lastest_version.php`
last_patch=`curl -s https://gestsup.fr/lastest_patch.php`
if [ $last_patch != $last_version ]
then
        last_version_number="${last_version//".zip"}"
        last_patch_number="${last_patch//".zip"}"
        last_patch_number=(${last_patch_number//./ })
        last_patch_number_short=${last_patch_number[2]} 
        last_version_number=(${last_version_number//./ })
        last_version_number_short=${last_version_number[2]} 
        for ((i=last_version_number_short+1;i<=last_patch_number_short;i++)); do
            patch_to_install=${last_version_number[0]}.${last_version_number[1]}.$i
            previous_patch=$(($i - 1))
            echo -n "      > Install patch $patch_to_install : "
            #download patch
            ${SUDO} -i wget -P /var/www/html https://gestsup.fr/downloads/versions/current/stable/patch_$patch_to_install.zip &> /dev/null
            if test -f "/var/www/html/patch_$patch_to_install.zip"
            then
                #extract patch files
                ${SUDO} -i unzip -o /var/www/html/patch_$patch_to_install.zip -d /var/www/html &> /dev/null
                #remove patch zip file
                ${SUDO} -i rm /var/www/html/patch_$patch_to_install.zip* &> /dev/null
                #update database
                update_db_file="/var/www/html/_SQL/update_"${last_version_number[0]}"."${last_version_number[1]}"."$previous_patch"_to_"$patch_to_install".sql"
                ${SUDO} -i mariadb  bsup < $update_db_file  &> /dev/null
                echo -e "\e[32mOK\e[0m"
            else 
                echo -e "\e[91mKO (error during download)\e[0m"
                exit;
            fi
        done   
    else
        echo -n "      > no new patch available : "
        echo -e "\e[32mOK\e[0m"
fi

echo -n "15 - Modify rights on files : "
${SUDO} -i adduser gestsup --ingroup www-data &> /dev/null
${SUDO} -i chown -R gestsup:www-data /var/www/html/ &> /dev/null
${SUDO} -i find /var/www/html/ -type d -exec chmod 750 {} \; &> /dev/null
${SUDO} -i find /var/www/html/ -type f -exec chmod 640 {} \; &> /dev/null
${SUDO} -i chmod 770 -R /var/www/html/upload &> /dev/null
${SUDO} -i chmod 770 -R /var/www/html/images/model &> /dev/null
${SUDO} -i chmod 770 -R /var/www/html/backup &> /dev/null
${SUDO} -i chmod 770 -R /var/www/html/_SQL &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "16 - Update Apache default parameters "
echo -n "      > ServerSignature : Off "
${SUDO} -i sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > ServerTokens : Prod "
${SUDO} -i sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > Remove Indexes from www directory "
${SUDO} -i sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf &> /dev/null
echo -e "\e[32mOK\e[0m"

echo "17 - Restart services "
echo -n "      > Apache : "
${SUDO} -i service apache2 restart  &> /dev/null
echo -e "\e[32mOK\e[0m"
echo -n "      > MariaDB : "
${SUDO} -i service mariadb restart  &> /dev/null
echo -e "\e[32mOK\e[0m"

echo -n "18 - MariaDB secure installation "
db_root_password=`tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''`
${SUDO} -i mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('$db_root_password');FLUSH PRIVILEGES;"
printf "$db_root_password\n y\n y\n y\n y\n y\n y\n" | ${SUDO} -i mysql_secure_installation &> /dev/null
echo -e "\e[32mOK\e[0m"

echo '';
echo -e '\e[32m-----------------------------------------------\e[0m';
echo -e '\e[32m----------------INSTALL COMPLETE---------------\e[0m';
echo -e '\e[32m-----------------------------------------------\e[0m';
echo ' '
echo -e "\e[32m> GestSup URL : http://$ip\e[0m"
echo -e '\e[32m> GestSup application username : admin\e[0m'
echo -e "\e[32m> GestSup application password : $admin_password\e[0m"
echo -e '\e[32m> GestSup database username : gestsup\e[0m'
echo -e "\e[32m> GestSup database password : $db_gestsup_password\e[0m"
echo -e "\e[32m> Database root password : $db_root_password\e[0m"
echo ' '
echo -e '\e[31mTo finish installation :\e[0m'
echo -e '\e[31m > Check application system page (Administration > System)\e[0m'
echo -e '\e[31m > Secure your server : https://doc.gestsup.fr/install/#securisation\e[0m'
echo ' '
