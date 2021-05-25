#!/usr/bin/env bash
# NOTE: this file should have Unix (LF) EOL conversion performed on it to avoid: "env: can't execute 'bash ': No such file or directory"

echo "Staring setup-env-then-start-wildfly-as-jboss.sh as user $(whoami) with params $@"

echo "DOCKER IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}"
echo "HELM_RELEASE_TIME=${HELM_RELEASE_TIME}"

# Add the jboss user to a new group named workaround with id 5000, for use by the NAS share
addgroup -g 5000 -S workaround
addgroup jboss workaround

# Copy the certificate files based on
# 1. https://stackoverflow.com/questions/55072221/deploying-postgresql-docker-with-ssl-certificate-and-key-with-volumes
# 2. https://itnext.io/postgresql-docker-image-with-ssl-certificate-signed-by-a-custom-certificate-authority-ca-3df41b5b53

#echo "Copying certificates like /var/lib/pegacorn-ssl-certs/ca.cer to /etc/ssl/certs/"

cp /var/lib/pegacorn-ssl-certs/ca.cer /etc/ssl/certs/pegacorn-ca.cer

chmod 400 /etc/ssl/certs/pegacorn-ca.cer
chown jboss:jboss /etc/ssl/certs/pegacorn-ca.cer 

ls -la /etc/ssl/certs/

mkdir -p /var/lib/pegacorn-keystores
cp /var/lib/pegacorn-ssl-certs/$KUBERNETES_SERVICE_NAME.$MY_POD_NAMESPACE.jks /var/lib/pegacorn-keystores/keystore.jks
cp /var/lib/pegacorn-ssl-certs/pegacorn-kie-execution-server.site-a-truststore.jks /var/lib/pegacorn-keystores/truststore.jks

chmod 400 /var/lib/pegacorn-keystores/keystore.jks
chown jboss:jboss /var/lib/pegacorn-keystores/keystore.jks 
chmod 400 /var/lib/pegacorn-keystores/truststore.jks
chown jboss:jboss /var/lib/pegacorn-keystores/truststore.jks 

ls -la /var/lib/pegacorn-keystores/

# then start /start-wildfly.sh script as jboss user
# NOTE: gosu is used instead of su-exec as the wildfly docker image is based on centos, whereas the postgres one is based on alpine,
# and the Alpine su-exec program is a substitute for gosu (see https://devops.stackexchange.com/a/5242 and
# https://github.com/docker-library/postgres/blob/33bccfcaddd0679f55ee1028c012d26cd196537d/12/docker-entrypoint.sh line 281 vs
# https://github.com/docker-library/postgres/blob/33bccfcaddd0679f55ee1028c012d26cd196537d/12/alpine/docker-entrypoint.sh line 281
exec gosu jboss "/start-wildfly.sh" "$@"
