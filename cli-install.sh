#!/bin/bash


DAEMON_VERSION=1.3.0
CLI_VERSION=2.0.0

BASE_DIR="${PUREVPN_BASE_DIR:-/opt}"
APP_DIR="$BASE_DIR/pure-linux"
DAEMON_FILE_NAME=pured-linux-x64
DAEMON_COMPRESSED_NAME=$DAEMON_FILE_NAME.gz
DAEMON_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/linux-daemon/$DAEMON_VERSION/$DAEMON_COMPRESSED_NAME

CLI_FILE_NAME=purevpn-cli
CLI_COMPRESSED_NAME=$CLI_FILE_NAME.gz
CLI_APP_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/linux-cli/$CLI_VERSION/$CLI_COMPRESSED_NAME

ATOM_CONFIG_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/atom-update-resolve-conf
ATOM_CONFIG_WG_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/atom-update-resolve-conf-wg

BIN_DIR=$APP_DIR/bin
LOG_DIR=$APP_DIR/log

install_pre_requisites() {
    echo "Installing the prerequisites"
    apt install -y \
        wget \
        gzip \
        apt-transport-https \
        openvpn \
        openvpn-systemd-resolved \
        wireguard \
        wireguard-tools \
        net-tools \
        openresolv
}

setting_up_required_files() {

    echo "Configuring required files"

    rm -rf $APP_DIR
    mkdir -p $APP_DIR
    mkdir $BIN_DIR
    mkdir $LOG_DIR

    wget --backups=0 --directory-prefix=$APP_DIR $ATOM_CONFIG_URL 
    
    #adding execute permissions
    chmod +x $APP_DIR/atom-update-resolve-conf

    wget --backups=0 --directory-prefix=$APP_DIR $ATOM_CONFIG_WG_URL 
    
    #adding execute permissions
    chmod +x $APP_DIR/atom-update-resolve-conf-wg
}

setting_up_daemon() {
    DAEMON_STATUS="$(systemctl is-active pured.service)"
    
    if [ "${DAEMON_STATUS}" = "active" ]; then
        echo "stopping daemon!"
        systemctl stop pured.service
        systemctl disable pured.service
        rm /etc/systemd/system/pured.service
        systemctl daemon-reload
        systemctl reset-failed
    fi

    wget --backups=0 --directory-prefix=$APP_DIR $DAEMON_URL 
    yes n | gzip -dv $APP_DIR/$DAEMON_COMPRESSED_NAME

    chmod +x $APP_DIR/$DAEMON_FILE_NAME

    printf "[Unit]\nDescription=purevpn-deamon\nAfter=network.target\n\n[Service]\nExecStart=$APP_DIR/$DAEMON_FILE_NAME --start\nRestart=always\nEnvironment=PATH=/usr/bin:/usr/local/bin\nEnvironment=NODE_ENV=production\nWorkingDirectory=/\nStandardOutput=file:${LOG_DIR}/access.log\nStandardError=file:${LOG_DIR}/error.log\n        \n[Install]\nWantedBy=multi-user.target" \
            > /etc/systemd/system/pured.service

    systemctl daemon-reload
    systemctl start pured
    systemctl enable pured
}

setting_up_cli() {
    #downloading the installer
    echo $CLI_APP_URL
    
    wget --backups=0 --directory-prefix=$BIN_DIR $CLI_APP_URL
    yes n | gzip -dv $BIN_DIR/$CLI_COMPRESSED_NAME

    chmod +x $BIN_DIR/$CLI_FILE_NAME

    if [[ $PATH != *"${BIN_DIR}"* ]]; then
        PATH=$PATH:$BIN_DIR/
    fi
}


install_pre_requisites
setting_up_required_files
setting_up_daemon
setting_up_cli

echo "Installation is completed, run the following command to load PureVPN CLI in your profile,"
echo "echo \"export PATH=\$PATH:$BIN_DIR\" >> ~/.bashrc"

echo $'\n'Run command \"purevpn-cli --help\" after to get more information on how to use PureVPN CLI
