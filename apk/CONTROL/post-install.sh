#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
# ------------------------------------------------------------------------------
# Save variables
APKG_PKG_DIR=/usr/local/AppCentral/${APKG_PKG_NAME}
APKG_PKG_SHORT_VER="${APKG_PKG_VER%-*}"
APKG_CFG_DIR=/share/Configuration/certbot
export APKG_CFG_DIR APKG_PKG_VER APKG_PKG_SHORT_VER
env | grep APKG | grep -v APKG_PKG_STATUS \
  | grep -v " " | sort > ${APKG_PKG_DIR}/.env.install

cd ${APKG_PKG_DIR:-/nonexistent} || exit 1
. ${APKG_PKG_DIR}/env

# Permissions
# ===========
# Ensure permissions are limited to root user for the application folder.
chown -R root:root ${APKG_PKG_DIR}


# User
# ====
useradd --system --no-create-home --home-dir ${APKG_CFG_DIR}/ --gid nogroup --shell /bin/false ${APKG_USER}


# Configuration folder
# ====================
mkdir -p ${APKG_CFG_DIR}
chown -R ${APKG_USER}:${APKG_GROUP} ${APKG_CFG_DIR}
chmod 750 ${APKG_CFG_DIR}


# Backups
# =======
mkdir ${APKG_CFG_DIR}/.backups/
as_date="$(date +%Y-%m-%d_%H%M)"
if test ! -f ${APKG_CFG_DIR}/crontab.${as_date}.bak; then
  crontab -l > ${APKG_CFG_DIR}/.backups/crontab.${as_date}.bak
fi
chown -R ${APKG_USER}:${APKG_GROUP} ${APKG_CFG_DIR}/.backups


# Configuration
# =============
# Don't override files that could have been user modified.
rsync -a --inplace --ignore-existing ${APKG_PKG_DIR}/conf.dist/ ${APKG_CFG_DIR}
chown -R ${APKG_USER}:${APKG_GROUP} ${APKG_CFG_DIR}


# Install
# =======

# First, install pipx application in a temporary folder
pip3 install --target ${APKG_TEMP_DIR} --force-reinstall --no-warn-script-location --progress-bar off --root-user-action=ignore --upgrade pipx || exit 1
_OLD_PATH=${PATH}
PATH="${APKG_TEMP_DIR}/bin:${PATH}"

# Install certbot and all dependencies
export PYTHONPATH="${APKG_TEMP_DIR}"
export PIPX_HOME=${APKG_PKG_DIR}/letsencrypt
export PIPX_BIN_DIR=${PIPX_HOME}/bin

logger "[${WHAT}] Installing certbot..."
pipx install -f certbot==${APKG_PKG_VER%-*} || exit 1

logger "[${WHAT}] Installing certbot plugins..."
pipx inject -f certbot certbot-apache==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-cloudflare==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-digitalocean==${APKG_PKG_VER%-*}
logger "[${WHAT}] Installing certbot plugins [20%]..."
pipx inject -f certbot certbot-dns-dnsimple==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-dnsmadeeasy==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-gehirn==${APKG_PKG_VER%-*}
logger "[${WHAT}] Installing certbot plugins [40%]..."
pipx inject -f certbot certbot-dns-google==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-linode==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-luadns==${APKG_PKG_VER%-*}
logger "[${WHAT}] Installing certbot plugins [60%]..."
pipx inject -f certbot certbot-dns-nsone==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-ovh==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-rfc2136==${APKG_PKG_VER%-*}
logger "[${WHAT}] Installing certbot plugins [80%]..."
pipx inject -f certbot certbot-dns-route53==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-dns-sakuracloud==${APKG_PKG_VER%-*}
pipx inject -f certbot certbot-nginx==${APKG_PKG_VER%-*}
logger "[${WHAT}] Installing certbot plugins [100%]..."


# Crontab
# =======
logger "[${WHAT}] Installing crontab..."
(crontab -l ; echo "0 */8 * * * ${APKG_PKG_DIR}/CONTROL/start-stop.sh reload") | sort | uniq | crontab -


# Restart
# =======
# Force a restart to generate a certificate if possible.
${APKG_PKG_DIR}/CONTROL/start-stop.sh force-restart

logger "[${WHAT}] Application installed."
exit 0
