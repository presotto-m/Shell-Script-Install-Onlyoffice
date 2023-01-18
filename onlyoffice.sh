#!/bin/bash

PARAMETERS="";
DOCKER="";
LOCAL_SCRIPTS="false"
HELP="false";

while [ "$1" != "" ]; do
	case $1 in
		-ls | --localscripts )
			if [ "$2" == "true" ] || [ "$2" == "false" ]; then
				PARAMETERS="$PARAMETERS ${1}";
				LOCAL_SCRIPTS=$2
				shift
			fi
		;;

		"-?" | -h | --help )
			HELP="true";
			DOCKER="true";
			PARAMETERS="$PARAMETERS -ht docs-install.sh";
		;;
	esac
	PARAMETERS="$PARAMETERS ${1}";
	shift
done

PARAMETERS="$PARAMETERS -it COMMUNITY";

root_checking () {
	if [ ! $( id -u ) -eq 0 ]; then
		echo "Para executar esta ação, você deve estar logado com direitos de root"
		exit 1;
	fi
}

command_exists () {
	type "$1" &> /dev/null;
}

install_curl () {
	if command_exists apt-get; then
		apt-get -y update
		apt-get -y -q install curl
	elif command_exists yum; then
		yum -y install curl
	fi

	if ! command_exists curl; then
		echo "comando curl não encontrado"
		exit 1;
	fi
}

read_installation_method () {
	echo "Selecione 'Y' para instalar o ONLYOFFICE Docs usando o Docker (recomendado). Selecione 'N' para instalá-lo usando pacotes RPM/DEB.";
	read -p "Install with Docker [Y/N/C]? " choice
	case "$choice" in
		y|Y )
			DOCKER="true";
		;;

		n|N )
			DOCKER="false";
		;;

		c|C )
			exit 0;
		;;

		* )
			echo "Por favor, digite S, N ou C para cancelar";
		;;
	esac

	if [ "$DOCKER" == "" ]; then
		read_installation_method;
	fi
}

root_checking

if ! command_exists curl ; then
	install_curl;
fi

if [ "$HELP" == "false" ]; then
	read_installation_method;
fi

if [ "$DOCKER" == "true" ]; then
	if [ "$LOCAL_SCRIPTS" == "true" ]; then
		bash install.sh ${PARAMETERS}
	else
		curl -s -O http://download.onlyoffice.com/docs/install.sh
		bash install.sh ${PARAMETERS}
		rm install.sh
	fi
else
	if [ -f /etc/redhat-release ] ; then
		DIST=$(cat /etc/redhat-release |sed s/\ release.*//);
		REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//);

		REV_PARTS=(${REV//\./ });
		REV=${REV_PARTS[0]};

		if [[ "${DIST}" == CentOS* ]] && [ ${REV} -lt 7 ]; then
			echo "CentOS 7 ou posterior é necessário";
			exit 1;
		fi

		if [ "$LOCAL_SCRIPTS" == "true" ]; then
			bash install-RedHat.sh ${PARAMETERS}
		else
			curl -s -O http://download.onlyoffice.com/docs/install-RedHat.sh
			bash install-RedHat.sh ${PARAMETERS}
			rm install-RedHat.sh
		fi
	elif [ -f /etc/debian_version ] ; then
		if [ "$LOCAL_SCRIPTS" == "true" ]; then
			bash install-Debian.sh ${PARAMETERS}
		else
			curl -s -O http://download.onlyoffice.com/docs/install-Debian.sh
			bash install-Debian.sh ${PARAMETERS}
			rm install-Debian.sh
		fi
	else
		echo "SO não suportado";
		exit 1;
	fi
fi
