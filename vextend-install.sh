#!/bin/bash

# Official VestaCP Extends Installation Script
# =============================================
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  Author: Brayan Rincon <brayan262@gmail.com>
#  Created: 11/05/2020
#  Last updated: 11/05/2020
#  Version: 1.0.0
#
#  Supported Operating Systems:
#  - CentOS 6/7/8 Minimal
#  - Ubuntu server 14.04/16.04/18.04
#  - Debian 7/8
#  - 32bit and 64bit

INSTALLER_VERSION="1.0.0"
INSTALLER_NAME="VestaCP-Extend-$INSTALLER_VERSION"
INSTALLER_LARGENAME="Vextends v$INSTALLER_VERSION | VestaCP Extends Tools"

REPO_VERSION="master"
REPO_NAME="VestaCP-Extend-$REPO_VERSION"
REPO="https://raw.githubusercontent.com/megacreativo/VestaCP-Extend/$REPO_VERSION"
PATCH_VEXTEND="/tmp/$REPO_NAME"


h1() {
    echo "\e[1m\e[34m$1\e[0m"
}

h2() {
    echo "\n\e[21m\e[94m$1\e[0m"
}

success() {
    echo "\e[42m\e[4m[Done]\e[0m $1"
}

failed() {
    echo -"\e[41m\e[4m[Fail]\e[0m $1"
}

# Am I root?
is_root(){
    if [ "x$(id -u)" != 'x0' ]; then
        failed 'Error: this script can only be executed by root'
        exit 1
    fi
}


#####################################################
### Display the 'welcome' splash/user warning info
#####################################################
welcome()
{
    clear
    echo ""
	h1 "__     __ _______  _______ _____ _   _ ____   "
	h1 "\ \   / /| ____\ \/ /_   _| ____| \ | |  _ \  "
    h1 " \ \ / / |  _|  \  /  | | |  _| |  \| | | | \ "
    h1 "  \ V /  | |___ /  \  | | | |___| |\  | |_| | "
    h1 "   \_/   |_____/_/\_\ |_| |_____|_| \_|____/  "
    echo ""
	echo $INSTALLER_LARGENAME
	echo "VestaCP functionality extension"
    echo "Copyright © 2020. Powered By Mega Creativo <http://megacreativo.com>"
    echo ""

	read -p "Enter the current port number: " CURRENT_PORT

	read -p "Enter the port number: " PORT_NUMBER

}


pre_install()
{
	cd /tmp

	wget -nv -q https://github.com/megacreativo/VestaCP-Extend/archive/master.zip

	unzip master.zip

}

#####################################################
### Activating FileManager
#####################################################
activate_filemanager()
{
	h2 "Starting FileManager Activation..."

	CHEKING_VESTA_FILEMANAGER="/etc/cron.hourly/vesta_filemanager"
	FILEMANAGER_DISABLED="FILEMANAGER_KEY=''"
	FILEMANAGER_ENABLED="FILEMANAGER_KEY='ILOVEREO'"

	create_shell_activate_filemanager(){
		echo '
		#!/bin/bash
		#  Author: Brayan Rincon <brayan262@gmail.com>
		#  Created: 11/05/2020
		#  Last updated: 11/05/2020
		#  Version: 1.0.0

		DISABLED="'${FILEMANAGER_DISABLED}'"
		ENABLED="'${FILEMANAGER_ENABLED}'"

		if ! grep -Fxq "$ENABLED" /usr/local/vesta/conf/vesta.conf; then
			# If it is not active it checks if it has a line but it is not activated

			# Checking if the disabled variable is the same in the file
			if grep -Fxq "$DISABLED" /usr/local/vesta/conf/vesta.conf
			then
				# Found TAG
				sed -i -e "s/$DISABLED/$ENABLED/g" /usr/local/vesta/conf/vesta.conf
			else
				# If there is no enabled or disabled line it activates
				echo $ENABLED >> /usr/local/vesta/conf/vesta.conf
			fi
		fi' >> $CHEKING_VESTA_FILEMANAGER
		chmod +x $CHEKING_VESTA_FILEMANAGER
		sudo echo "Enabling File Manager..."

		# Verifying and Updating file sudoers
		TEXT_FOR_SUDOERS='admin  ALL=(ALL) NOPASSWD: ALL'
		SUDOERS='/etc/sudoers'

		if ! grep -Fxq "$TEXT_FOR_SUDOERS" $SUDOERS; then
			echo $TEXT_FOR_SUDOERS >> $SUDOERS
		fi

		### Adding task for the admin to activate FileManager
		/usr/local/vesta/bin/v-add-cron-job admin "*/2" "*" "*" "*" "*" "sudo /bin/bash /etc/cron.hourly/vesta_filemanager"
		bash $CHEKING_VESTA_FILEMANAGER

		success "FileManager Successfully Activated!"
	}

	# Checks whether it is a reboot or a new installation
	if [ -f "$CHEKING_VESTA_FILEMANAGER" ]; then
		echo "Clearing Previous Activation ..."
		rm $CHEKING_VESTA_FILEMANAGER
		create_shell_activate_filemanager
	else
		create_shell_activate_filemanager
	fi
}


#####################################################
### Install Templates
#####################################################
install_templates()
{
	h2 "Install Templates..."

	PATCH_ORIGIN="$PATCH_VEXTEND/vesta/data/templates/web/apache2"
		
	cp -R PATCH_ORIGIN "/usr/local/vesta/data/templates/web"

	success "Templates Installed!"
}


#####################################################
### Fixe phpMyAdmin
#####################################################
phpMyAdmin_Fixer()
{
	# bash <(curl -s https://raw.githubusercontent.com/luizjr/phpMyAdmin-Fixer-VestaCP/master/pma.sh)
	echo ''
}


#####################################################
### Install WwordPress
#####################################################
install_wordpress()
{
	h2 "Install WordPress"

	WPCLI=/usr/local/vesta/bin/wp

	# Check if WP CLI is Installed // Install WP CLI
	if test -f "$WPCLI"; then
		success "WP-CLI already installed."
		echo "This Script Will Update VeataCP Wordpress Installer"
		cd /usr/local/vesta/bin
		curl -O  https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
		mv wp-cli.phar wp
		chmod +x wp
		success "WP-CLI ppdated succefully."
	else
		# Installing WP-CLI
		echo "Installing WP CLI"
		cd /usr/local/vesta/bin
		curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
		mv wp-cli.phar wp
		chmod +x wp
		mkdir /usr/local/vesta/web/installers
		mkdir /usr/local/vesta/web/installers/wordpress
		success "WP-CLI installed succefully."
	fi

	cp -R "$PATCH_VEXTEND/bin/v-install-wordpress" "/usr/local/vesta/bin"
	chmod 770 v-install-wordpress
	chmod +x v-install-wordpress

	cp -R "$PATCH_VEXTEND/web/installers/wordpress" /usr/local/vesta/web/installers
	
	cp -R "$PATCH_VEXTEND/web/templates/admin/" /usr/local/vesta/web/templates
	
	# Add to Navigation Admin User
    if grep -q "WordPress" /usr/local/vesta/web/templates/admin/panel.html; then
        success "VestaCP WordPress it already exists"
    else 
		TAB="<?php if(\$TAB == 'WordPress') echo 'l-menu__item--active'; ?>"
		LINKWP="<div class='l-menu__item \$TAB'><a href='/installers/wordpress/'><?=__('WordPress')?></a></div>"
        sed -i "/<div class=\"l-menu clearfix noselect\">/a $LINKWP" /usr/local/vesta/web/templates/admin/panel.html;
    fi

	success "VestaCP Wordpress Application Installer is SUCCESSFULLY INSTALLED/UPDATED"
}


install_multiphp()
{

	wget -nv -q "$REPO/installers/php/multi-php-install.sh"

	chmod a+x multi-php-install.sh

	sh multi-php-install.sh

}


change_port_vestacp()
{
	h2 "Change Port VestaCP"

	sed -i "s/listen          $CURRENT_PORT/listen          $PORT_NUMBER/g" /usr/local/vesta/nginx/conf/nginx.conf;

	/usr/local/vesta/bin/v-add-firewall-rule ACCEPT 0.0.0.0/0 $PORT_NUMBER TCP VESTA

    service vesta restart

	success "Change Port VestaCP: $PORT_NUMBER"

}


install_composer()
{
	h2 "Install Composer"

	cd /tmp

	curl -sS https://getcomposer.org/installer | php

	sudo mv composer.phar /usr/local/bin/composer

}


#####################################################
### Exit
#####################################################
finalize()
{
	rm -rf PATCH_VEXTEND
	rm -rf "/tmp/master.zip"

	echo "Closing the application ." 
	sleep 2 && clear
	exit
}


#####################################################
### Setup
#####################################################
setup(){
	is_root
	welcome
	
	pre_install

	install_composer
	install_wordpress
	install_templates
	#install_ssl_to_panel

	activate_filemanager
	#change_port_vestacp

	finalize
	
}
setup
