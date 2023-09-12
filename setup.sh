#!/bin/bash
#########################################################
# Este script deve ser executado assim:
#
#   curl https://seudominio/setup.sh | sudo bash
#
#########################################################

if [ -z "$TAG" ]; then
	# If a version to install isn't explicitly given as an environment
	# variable, then install the latest version. But the latest version
	# depends on the machine's version of Ubuntu. Existing users need to
	# be able to upgrade to the latest version available for that version
	# of Ubuntu to satisfy the migration requirements.
	#
	# Also, the system status checks read this script for TAG = (without the
	# space, but if we put it in a comment it would confuse the status checks!)
	# to get the latest version, so the first such line must be the one that we
	# want to display in status checks.
	#
	# Allow point-release versions of the major releases, e.g. 22.04.1 is OK.
	UBUNTU_VERSION=$( lsb_release -d | sed 's/.*:\s*//' | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]/\1/' )
	if [ "$UBUNTU_VERSION" == "Ubuntu 22.04 LTS" ]; then
		# This machine is running Ubuntu 22.04, which is supported by
		# Mail-in-a-Box versions 60 and later.
		TAG=v64
	elif [ "$UBUNTU_VERSION" == "Ubuntu 18.04 LTS" ]; then
		# This machine is running Ubuntu 18.04, which is supported by
		# Mail-in-a-Box versions 0.40 through 5x.
		echo "O suporte para Ubuntu 18.04 está terminando."
		echo "Comece imediatamente a migrar seus dados para"
		echo "uma nova máquina rodando Ubuntu 22.04. Ver:"
		echo "https://mailinabox.email/maintenance.html#upgrade"
		TAG=v57a
	elif [ "$UBUNTU_VERSION" == "Ubuntu 14.04 LTS" ]; then
		# This machine is running Ubuntu 14.04, which is supported by
		# Mail-in-a-Box versions 1 through v0.30.
		echo "Ubuntu 14.04 is no longer supported."
		echo "A última versão do Sistema compatível com Ubuntu 14.04 será instalada."
		TAG=v0.30
	else
		echo "Este script pode ser usado apenas em uma máquina executando Ubuntu 14.04, 18.04 ou 22.04."
		exit 1
	fi
fi

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "Este script deve ser executado como root. Você deixou de fora o sudo?"
	exit 1
fi

# Clone the Mail-in-a-Box repository if it doesn't exist.
if [ ! -d $HOME/mailinabox ]; then
	if [ ! -f /usr/bin/git ]; then
		echo Instalando o git . . .
		apt-get -q -q update
		DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
		echo
	fi

	echo Baixando AutoConfigurador $TAG. . .
	git clone \
		-b $TAG --depth 1 \
		https://github.com/chakaldevelopers/autoconfiginbox \
		$HOME/mailinabox \
		< /dev/null 2> /dev/null

	echo
fi

# Change directory to it.
cd $HOME/mailinabox

# Update it.
if [ "$TAG" != $(git describe --always) ]; then
	echo Atualizando e Verificando Serial Licenca $TAG . . .
	git fetch --depth 1 --force --prune origin tag $TAG
	if ! git checkout -q $TAG; then
		echo "Atualização falhou. Você modificou algo em $(pwd)?"
		exit 1
	fi
	echo
fi

# Start setup script.
setup/start.sh
