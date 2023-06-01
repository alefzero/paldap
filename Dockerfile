FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive 
ENV PALDAP_USER=paldap
ENV PALDAP_HOME=/opt/openldap
ENV PALDAP_DATA=${PALDAP_HOME}/data
ENV PALDAP_CONFIG=${PALDAP_HOME}/config
ENV PALDAP_LDIF=${PALDAP_HOME}/ldif
ENV PALDAP_CONFIGURED_FILE=${PALDAP_HOME}/.PALDAP-configured
ENV PATH $PATH:${PALDAP_HOME}

# Superuser tasks
RUN apt-get update && apt-get -y upgrade && apt-get -y autoremove
RUN apt-get install -y slapd sudo

# Copy artefacts and configure it
WORKDIR ${PALDAP_HOME}

## Grant some ldap super user actions to app user (least privilege)
RUN echo "${PALDAP_USER} ALL = NOPASSWD:SETENV: /usr/sbin/service slapd *,  /usr/bin/ldapmodify *, ${PALDAP_HOME}/config.sh, /usr/sbin/slapd, /usr/bin/killall slapd" > /etc/sudoers.d/padl-ldap-sudoers

# User configuration
RUN groupadd ${PALDAP_USER}; useradd -s /bin/bash -m -g ${PALDAP_USER} -G users ${PALDAP_USER}
RUN mkdir -p ${PALDAP_HOME} ${PALDAP_CONFIG} ${PALDAP_CONFIG_LDIF} ${PALDAP_DATA} ${PALDAP_LDIF}

ADD run.sh ${PALDAP_HOME}
ADD config.sh ${PALDAP_HOME}

RUN chown -R ${PALDAP_USER}:${PALDAP_USER} ${PALDAP_HOME} ${PALDAP_CONFIG} ${PALDAP_LDIF} ${PALDAP_DATA}

USER ${PALDAP_USER}
WORKDIR ${PALDAP_HOME}
RUN chmod 500 run.sh config.sh

# Entrypoint
ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "${PALDAP_HOME}/run.sh" ]