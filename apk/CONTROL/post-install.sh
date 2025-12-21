#!/bin/sh
# SPDX-License-Identifier: MIT
#
# ------------------------------------------------------------------------------
# Save variables
APKG_PKG_DIR=/usr/local/AppCentral/${APKG_PKG_NAME}
APKG_PKG_SHORT_VER="${APKG_PKG_VER%-*}"
APKG_CFG_DIR=/share/Configuration/certbot
APKG_TAR_FILE=/tmp/certbot.tar.xz
export APKG_CFG_DIR APKG_PKG_VER APKG_PKG_SHORT_VER
env | grep APKG | grep -v " " | sort > ${APKG_PKG_DIR}/.env.install

# Ensure permissions are limited to root user for the application folder.
chown -R root:root ${APKG_PKG_DIR}

# Create a configuration folder for this application
if test ! -d ${APKG_CFG_DIR}; then
  mkdir -p ${APKG_CFG_DIR}
  chown admin:root ${APKG_CFG_DIR}
  chmod 750 ${APKG_CFG_DIR}
fi

# First, install a pipx application in a temporary folder
pip3 install --target ${APKG_TEMP_DIR} --force-reinstall --no-warn-script-location --progress-bar off --root-user-action=ignore --upgrade pipx

# Install the certbot application in the final destination folder
_OLD_PATH=${PATH}
PATH="${APKG_TEMP_DIR}/bin:${PATH}"

export PYTHONPATH="${APKG_TEMP_DIR}"
export PIPX_HOME=${APKG_PKG_DIR}
export PIPX_BIN_DIR=${PIPX_HOME}/bin
pipx install -f certbot==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-apache==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-cloudflare==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-digitalocean==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-dnsimple==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-dnsmadeeasy==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-gehirn==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-google==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-linode==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-luadns==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-nsone==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-ovh==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-rfc2136==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-route53==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-sakuracloud==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-nginx==${APKG_PKG_VER%-*}

# Copy deploy scripts, overwrite
mkdir -p ${APKG_CFG_DIR}/letsencrypt/renewal-hooks/deploy
cp -frv ${APKG_PKG_DIR}/renewal-hooks/deploy/* ${APKG_CFG_DIR}/letsencrypt/renewal-hooks/deploy/

# Copy available configurations if they don't exist
rsync -av --inplace --ignore-existing ${APKG_PKG_DIR}/conf.dist/ ${APKG_CFG_DIR}
chown -R admin:root ${APKG_CFG_DIR}
chmod 750 ${APKG_CFG_DIR}
chmod 600 ${APKG_CFG_DIR}/*.conf

# Make backup of the crontab
if test ! -f ${APKG_CFG_DIR}/crontab.$(date +%Y-%m-%d_%H%M).bak; then
  crontab -l > ${APKG_CFG_DIR}/crontab.$(date +%Y-%m-%d_%H%M).bak
fi

# Add a line to crontab
(crontab -l ; echo "0 */8 * * * ${APKG_PKG_DIR}/bin/certbot-renew") | sort | uniq | crontab -

# Start the service in case configuration already existed and was valid
touch "${APKG_CFG_DIR}/active"
${APKG_PKG_DIR}/bin/certbot-renew

exit 0
