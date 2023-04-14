#!/bin/bash


DAEMON_VERSION=1.3.0
CLI_VERSION=2.0.0

APP_DIR=/tmp
DAEMON_FILE_NAME=pured-linux-x64
DAEMON_COMPRESSED_NAME=$DAEMON_FILE_NAME.gz
DAEMON_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/linux-daemon/$DAEMON_VERSION/$DAEMON_COMPRESSED_NAME

CLI_FILE_NAME=purevpn-cli
CLI_COMPRESSED_NAME=$CLI_FILE_NAME.gz
CLI_APP_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/linux-cli/$CLI_VERSION/$CLI_COMPRESSED_NAME

ATOM_CONFIG_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/atom-update-resolve-conf
ATOM_CONFIG_WG_URL=https://purevpn-dialer-assets.s3.amazonaws.com/cross-platform/atom-update-resolve-conf-wg

CLI_INSTALLATION_DIR=/etc/pure-linux-cli

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

    rm -rf $APP_DIR/atom-update-resolve-conf
    wget --backups=0 --directory-prefix=$APP_DIR $ATOM_CONFIG_URL 
    
    #adding execute permissions
    chmod +x $APP_DIR/atom-update-resolve-conf

    rm -rf $APP_DIR/atom-update-resolve-conf-wg
    wget --backups=0 --directory-prefix=$APP_DIR $ATOM_CONFIG_WG_URL 
    
    #adding execute permissions
    chmod +x $APP_DIR/atom-update-resolve-conf-wg
}

setting_up_daemon() {
    DAEMON_STATUS="$(systemctl is-active pured.service)"
    
    if [ "${DAEMON_STATUS}" = "active" ]; then
        echo "stopping daemon!"
        systemctl disable pured.service
        rm /etc/systemd/system/pured.service
        systemctl daemon-reload
        systemctl reset-failed
    fi

    rm -rf /tmp/$DAEMON_COMPRESSED_NAME
    wget --backups=0 --directory-prefix=/tmp $DAEMON_URL 
    yes n | gzip -dv /tmp/$DAEMON_COMPRESSED_NAME

    chmod +x /tmp/$DAEMON_FILE_NAME

    printf "[Unit]\nDescription=purevpn-deamon\nAfter=network.target\n\n[Service]\nExecStart=/tmp/$DAEMON_FILE_NAME --start\nRestart=always\nEnvironment=PATH=/usr/bin:/usr/local/bin\nEnvironment=NODE_ENV=production\nWorkingDirectory=/\nStandardOutput=file:${APP_DIR}/access.log\nStandardError=file:${APP_DIR}/error.log\n        \n[Install]\nWantedBy=multi-user.target" \
            > /etc/systemd/system/pured.service

    systemctl daemon-reload
    systemctl start pured
    systemctl enable pured
}

setting_up_cli() {
    #downloading the installer
    echo $CLI_APP_URL
    
    rm -rf /tmp/$CLI_COMPRESSED_NAME
    wget --backups=0 --directory-prefix=/tmp $CLI_APP_URL
    yes n | gzip -dv /tmp/$CLI_COMPRESSED_NAME

    rm -rf $CLI_INSTALLATION_DIR/
    mkdir $CLI_INSTALLATION_DIR/

    cp /tmp/$CLI_FILE_NAME $CLI_INSTALLATION_DIR/
    chmod +x $CLI_INSTALLATION_DIR/$CLI_FILE_NAME

    if [[ $PATH != *"${CLI_INSTALLATION_DIR}"* ]]; then
        PATH=$PATH:$CLI_INSTALLATION_DIR/
    fi
}


install_pre_requisites
setting_up_required_files
setting_up_daemon
setting_up_cli

echo "Installation is completed, run the following command to load PureVPN CLI in your profile,"
echo `echo "PATH=$PATH:$CLI_INSTALLATION_DIR/" \> \~/.bashrc`

echo $'\n'Run command \"purevpn-cli --help\" after to get more information on how to use PureVPN CLI