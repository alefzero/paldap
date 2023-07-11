#!/bin/bash
set -e

trap end_padl_app INT TERM

# Enviroment variables 
export PALDAP_DEFAULT_BASE_DN="${PALDAP_DEFAULT_BASE_DN:-dc=example,dc=com}"
export PALDAP_ADMIN_CONFIG_USER="${PALDAP_ADMIN_CONFIG_USER:-cn=config}"
export PALDAP_ADMIN_CONFIG_PASSWORD="${PALDAP_ADMIN_CONFIG_PASSWORD:-configadminpassword}"
export PALDAP_ADMIN_USER="${PALDAP_ADMIN_USER:-cn=admin,${PALDAP_DEFAULT_BASE_DN}}"
export PALDAP_ADMIN_PASSWORD="${PALDAP_ADMIN_PASSWORD:-adminpassword}"
export PALDAP_LOAD_EXTRA_MODULES="${PALDAP_LOAD_EXTRA_MODULES:dyngroup}"
export PALDAP_LOG_LEVEL="${PALDAP_LOG_LEVEL:=conns}"

end_padl_app() {
    echo "Shutting down ldap..."
}

. /etc/default/slapd

echo "Staring configuration phase..."
sudo -E ${PALDAP_HOME}/config.sh
if pgrep slapd
then
    sudo /usr/bin/killall slapd
fi
echo "Restarting ldap service..."
sudo /usr/sbin/slapd -h "ldap:/// ldapi:///" -g openldap -u openldap -F /opt/openldap/data -d  ${PALDAP_LOG_LEVEL}

# debug levels: slapd -d ?