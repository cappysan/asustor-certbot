#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
# ------------------------------------------------------------------------------
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1
if test -f ${APKG_PKG_DIR}/env; then
  . ${APKG_PKG_DIR}/env
fi

# To install files on installation, we need to have the variables set
export APKG_CFG_DIR=/share/Configuration/certbot

# Logrotate
# =========
# Enable logrotate
cp -f ${APKG_CFG_DIR}/deps.d/logrotate.d/* /etc/logrotate.d/

# Renewal Hooks
# =============
# Copy all renewal-hooks from installed packages to Configuration folder
mkdir -p ${APKG_CFG_DIR}/letsencrypt/renewal-hooks/

# Install configuration files
# post-install installs the files from PKG_DIR to CFG_DIR, with no overwrite.
# if user modifies the CFG_DIR files, that those modifications into account.
for as_dir in /share/Configuration/*/deps.d/certbot/renewal-hooks/; do
  if test -d "${as_dir}"; then
    rsync -a --inplace ${as_dir}/ ${APKG_CFG_DIR}/letsencrypt/renewal-hooks/
  fi
done

# Permissions
# ===========
# Ensure some permission limits on the files that may contain some tokens
for as_file in credentials cloudflare digitalocean dnsimple dnsmadeeasy gehirn google linode luadns nsone ovh rfc2136 route53 sakuracloud; do
  chmod -f 600 ${APKG_CFG_DIR}/${as_file}.conf >/dev/null 2>&1
done

exit 0
