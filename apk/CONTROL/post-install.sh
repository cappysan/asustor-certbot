#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
# ------------------------------------------------------------------------------
# Save variables
APKG_PKG_DIR=/usr/local/AppCentral/${APKG_PKG_NAME}
APKG_PKG_SHORT_VER="${APKG_PKG_VER%-*}"
APKG_CFG_DIR=/share/Configuration/certbot
export APKG_CFG_DIR APKG_PKG_VER APKG_PKG_SHORT_VER
env | grep APKG | grep -v " " | sort > ${APKG_PKG_DIR}/.env.install

${APKG_PKG_DIR}/CONTROL/common.sh


# Install
# =======

# First, install a pipx application in a temporary folder
pip3 install --target ${APKG_TEMP_DIR} --force-reinstall --no-warn-script-location --progress-bar off --root-user-action=ignore --upgrade pipx || exit 1

# Install the certbot application in the final destination folder
_OLD_PATH=${PATH}
PATH="${APKG_TEMP_DIR}/bin:${PATH}"

# Install certbot and all dependencies
export PYTHONPATH="${APKG_TEMP_DIR}"
export PIPX_HOME=${APKG_PKG_DIR}
export PIPX_BIN_DIR=${PIPX_HOME}/bin
pipx install -f certbot==${APKG_PKG_VER%-*} || exit 1
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


# Crontab
# =======

(crontab -l ; echo "0 */8 * * * ${APKG_PKG_DIR}/bin/certbot-renew") | sort | uniq | crontab -

# Logrotate
# =========
# Enable logrotate
cp -f ${APKG_PKG_DIR}/logrotate.d/cappysan-certbot /etc/logrotate.d/

# Restart
# =======
if test -f "${APKG_CFG_DIR}/active"; then
  ${APKG_PKG_DIR}/bin/certbot-renew
fi

exit 0
