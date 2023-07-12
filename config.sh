#!/bin/bash
# set -x
set -e

pushd() {
    command pushd $@ > /dev/null
}

popd() {
    command popd $@ > /dev/null
}

createOpenldapDB() {
    echo "Creating LDAP structure"

    pushd ${PALDAP_DATA}
    local initldif="${PALDAP_CONFIG}/slapd.init.ldif"

    sed -i "s;SLAPD_CONF=;SLAPD_CONF=${PALDAP_DATA};g" /etc/default/slapd
    
    cp /usr/share/slapd/slapd.init.ldif ${initldif}

    sed -i -e "s|@SUFFIX@|${PALDAP_DEFAULT_BASE_DN}|g" ${initldif}
    sed -i -e "s|@PASSWORD@|${PALDAP_ADMIN_PASSWORD}|g" ${initldif}
    sed -i -e "s|olcDbDirectory: /var/lib/ldap|olcDbDirectory: ${PALDAP_DATA}|g" ${initldif}
    slapadd -F "${PALDAP_DATA}" -b "cn=config" -l "${initldif}" 

    chown -R openldap.openldap ${PALDAP_DATA}/

    rm -f "${initldif}"
    popd

}

changeRootPassword() {
        local PASS=$(slappasswd -h {SSHA} -s ${PALDAP_ADMIN_CONFIG_PASSWORD})

    cat << EOF | ldapmodify -Y EXTERNAL -H ldapi:/// -a 
# Change cn=admin,cn=config password
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $PASS    
EOF


}

configureModules() {
    echo "Setting up modules"

    for module in $PALDAP_LOAD_EXTRA_MODULES
    do
        local module_ldif="/etc/ldap/schema/${PALDAP_LOAD_EXTRA_MODULES}.ldif"
        if [ -f "${module_ldif}" ]
        then
            echo "Setting up module ${PALDAP_LOAD_EXTRA_MODULES}"
            cat ${module_ldif} | ldapmodify -Y EXTERNAL -H ldapi:/// -a 
        else
            echo "Module ${module} not found. Exiting"
            exit 1
        fi
    done

#     cat << EOF | ldapmodify -Y EXTERNAL -H ldapi:/// -a 
# dn: cn=module{0},cn=config
# changetype: modify
# add: olcModuleLoad
# olcModuleLoad: memberof

# dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
# changetype: add
# objectClass: olcConfig
# objectClass: olcMemberOf
# objectClass: olcOverlayConfig
# objectClass: top
# olcOverlay: memberof
# olcMemberOfRefint: TRUE
# EOF

}



configureUserConf() {
    echo "Applying user configuration"
    for userfile in $PALDAP_LDIF/*
    do
        echo "Adding user configuration file $userfile"
        cat ${userfile} | ldapmodify -Y EXTERNAL -H ldapi:/// -a 
    done
}

removeOldLdapFiles() {
    pushd ${PALDAP_DATA}
    find . -not -path "." -delete
    popd    
}

if [ -f ${PALDAP_CONFIGURED_FILE} ] && grep -q "status=delete" ${PALDAP_CONFIGURED_FILE}
then
    removeOldLdapFiles
fi

echo "Running configuration"
if [ ! -f ${PALDAP_CONFIGURED_FILE} ]
then
    echo "Setting up the LDAP"
    createOpenldapDB
    /etc/init.d/slapd start
    changeRootPassword
    configureModules
    configureUserConf
    echo "status=configured" >  ${PALDAP_CONFIGURED_FILE}
else
    echo  "Previous LDAP configuration found."
fi

chown -R openldap.openldap ${PALDAP_DATA}/
chown -R ${PALDAP_USER}.${PALDAP_USER} ${PALDAP_CONFIGURED_FILE}

echo "LDAP configured"

