# PALDAP - A pal ldap environment for simple deployments

This image uses an openldap installation under a Ubuntu LTS for quick and easy deploy and customization.

Enviroment variables can be use to customize the behavior:

Variable|Usage|Default Value
---|---|---
PALDAP_USER | OS user to be applied at the image | paldap for application, openldap for ldap files
PALDAP_HOME | Folder where application resides | /opt/openldap
PALDAP_DATA | LDAP data folder | ${PALDAP_HOME}/data
PALDAP_CONFIG | Application configuration data | ${PALDAP_HOME}/config
PALDAP_LDIF | Location of extra schema/ldif files to be loaded at configuration phase. All files here are applied at configuration time | ${PALDAP_HOME}/ldif
PALDAP_DEFAULT_BASE_DN | Root DN to be used | dc=example,dc=com
PALDAP_ADMIN_CONFIG_PASSWORD | cn=admin,cn=config password | configadminpassword
PALDAP_ADMIN_USER| Administrator user |cn=admin,${PALDAP_DEFAULT_BASE_DN}
PALDAP_ADMIN_PASSWORD| Administrator password |adminpassword
PALDAP_LOAD_EXTRA_MODULES| Load extra overlays. By default add the dynamic group with memberof configuration* |dyngroup
PALDAP_LOG_LEVEL | Log level for this openldap | filter
