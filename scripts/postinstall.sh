#!/bin/bash

_scriptDir="/opt/stenographer"

add_accounts () {
	if ! id stenographer &>/dev/null; then
		echo "Setting up stenographer user"
		sudo adduser --system --no-create-home stenographer
	fi
	if ! getent group stenographer &>/dev/null; then
		echo "Setting up stenographer group"
		sudo addgroup --system stenographer
	fi
}
install_certs () {
    sudo /opt/stenographer/stenokeys.sh stenographer stenographer
}

install_configs () {
	cd $_scriptDir

	echo "Setting up stenographer conf directory"
	if [ ! -d /etc/stenographer/certs ]; then
		sudo mkdir -p /etc/stenographer/certs
		sudo chown -R root:root /etc/stenographer/certs
	fi
	if [ ! -f /etc/stenographer/config ]; then
		sudo cp -vf configs/steno.conf /etc/stenographer/config
		sudo chown root:root /etc/stenographer/config
		sudo chmod 644 /etc/stenographer/config
	fi
	sudo chown root:root /etc/stenographer

	if grep -q /path/to /etc/stenographer/config; then
		mkdir -p /var/lib/stenographer
		sudo chown -R stenographer:stenographer /var/lib/stenographer
		sudo sed -i 's/\/path\/to/\/var\/lib\/stenographer/g' /etc/stenographer/config
		echo "WARNING! Create output directories and update settings in /etc/stenographer/config"
	fi
}

do_permissions () {
	export BINDIR="${BINDIR-/usr/bin}"
	sudo chown stenographer:root "$BINDIR/stenographer"
	sudo chmod 700 "$BINDIR/stenographer"
	sudo chown stenographer:root "$BINDIR/stenotype"
	sudo chmod 0500 "$BINDIR/stenotype"
	SetCapabilities "$BINDIR/stenotype"
	sudo chown root:root "$BINDIR/stenoread"
	sudo chmod 0755 "$BINDIR/stenoread"
	sudo chown root:root "$BINDIR/stenocurl"
	sudo chmod 0755 "$BINDIR/stenocurl"
}

install_service () {
	cd $_scriptDir

	if [ ! -f /etc/security/limits.d/stenographer.conf ]; then
		echo "Setting up stenographer limits"
		sudo cp -v configs/limits.conf /etc/security/limits.d/stenographer.conf
	fi

	if [ ! -f /etc/systemd/system/stenographer.service ]; then
		echo "Installing stenographer systemd service"
		sudo cp -v configs/systemd.conf /etc/systemd/system/stenographer.service
		sudo chmod 0644 /etc/systemd/system/stenographer.service
	fi
}

function SetCapabilities {
  sudo setcap 'CAP_NET_RAW+ep CAP_NET_ADMIN+ep CAP_IPC_LOCK+ep' "$1"
}


add_accounts
install_configs
do_permissions
install_service
install_certs

echo "stenographer is ready."
