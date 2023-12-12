#!/bin/bash

dive="false"
action="install"

. <(wget -qO- https://raw.githubusercontent.com/semalis/utils/master/bashbuilder/colors.sh) --

function option_value() { 
        echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g';
}

function install() {
  if [ -f ~/.bash_profile ];
  then
    echo -e "${C_LGn}File bash_profile is exist${RES}"
  else
    echo -e "${C_LGn}Make necessary link to file bash_profile${RES}"
    ln -s ~/.profile ~/.bash_profile
  fi

	cd
	if ! docker --version; then

		echo -e "${C_LGn}Update & Upgrade your system ...${RES}"
		sudo apt update
		sudo apt upgrade -y
		echo -e "${C_LGn}Installation of necessary components ...${RES}"
		sudo apt install curl apt-transport-https ca-certificates gnupg lsb-release -y

		echo -e "${C_LGn}Docker installation...${RES}"
		. /etc/os-release
		wget -qO- "https://download.docker.com/linux/${ID}/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt update
		sudo apt install docker-ce docker-ce-cli containerd.io -y
		docker_version=`apt-cache madison docker-ce | grep -oPm1 "(?<=docker-ce \| )([^_]+)(?= \| https)"`
		sudo apt install docker-ce="$docker_version" docker-ce-cli="$docker_version" containerd.io -y
	fi
	if ! docker-compose --version; then
		echo -e "${C_LGn}Docker Сompose installation...${RES}"
		sudo apt update
		sudo apt upgrade -y
		sudo apt install wget jq -y
		local docker_compose_version=`wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name"`
		sudo wget -O /usr/bin/docker-compose "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`"
		sudo chmod +x /usr/bin/docker-compose
		. $HOME/.bash_profile
	fi
	if [ "$dive" = "true" ] && ! dpkg -s dive | grep -q "ok installed"; then
		echo -e "${C_LGn}Dive installation...${RES}"
		wget https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
		sudo apt install ./dive_0.9.2_linux_amd64.deb
		rm -rf dive_0.9.2_linux_amd64.deb
	fi
}

function uninstall() {
	echo -e "${C_LGn}Docker uninstalling...${RES}"
	sudo dpkg -r dive
	sudo systemctl stop docker.service docker.socket
	sudo systemctl disable docker.service docker.socket
	sudo rm -rf `systemctl cat docker.service | grep -oPm1 "(?<=^#)([^%]+)"` `systemctl cat docker.socket | grep -oPm1 "(?<=^#)([^%]+)"` /usr/bin/docker-compose
	sudo apt purge docker-engine docker docker.io docker-ce docker-ce-cli -y
	sudo apt autoremove --purge docker-engine docker docker.io docker-ce -y
	sudo apt autoclean
	sudo rm -rf /var/lib/docker /etc/appasudo rmor.d/docker
	sudo groupdel docker
	sudo rm -rf /etc/docker /usr/bin/docker /usr/libexec/docker /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-scan /usr/libexec/docker/cli-plugins/docker-app /usr/share/keyrings/docker-archive-keyring.gpg
}

while test $# -gt 0; do
	case "$1" in
	-h|--help)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs or uninstalls Docker"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help       show the help page"
		echo -e "  -d, --dive       install Dive (images analyser)"
		echo -e "  -u, --uninstall  uninstall Docker (${C_R}completely delete all images and containers${RES})"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "Script URL: http://-/Utils/raw/branch/main/Installers/docker.sh"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-d|--dive)
		dive="true"
		shift
		;;
	-u|--uninstall)
		action="uninstall"
		shift
		;;
	*|--)
		break
		;;
	esac
done

$action

echo -e "${C_LGn}Done!${RES}"
