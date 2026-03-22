#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
# ------------------------------------------------------------------------------
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1

function logger() {
  echo "${@}" >&2
  syslog --log 0 --level 0 --user SYSTEM --event "${@}"
}

# Logrotate
# =========
# Enable logrotate
cp -f ${APKG_CFG_DIR}/logrotate.d/* /etc/logrotate.d/


# Renewal Hooks
# =============
# Copy all renewal-hooks.dist/* to Configuration folder
mkdir -p ${APKG_CFG_DIR}/letsencrypt/renewal-hooks/
for as_dir in /usr/local/AppCentral/cappysan-*/renewal-hooks.dist; do
  if test -d "${as_dir}"; then
    rsync -a --inplace --ignore-existing ${as_dir}/ \
      ${APKG_CFG_DIR}/letsencrypt/renewal-hooks/
  fi
done


# Permissions
# ===========
# Ensure some permission limits on the files that may contain some tokens
for as_file in credentials cloudflare digitalocean dnsimple dnsmadeeasy gehirn google linode luadns nsone ovh rfc2136 route53 sakuracloud; do
  chmod -f 640 ${APKG_CFG_DIR}/${as_file}.conf >/dev/null 2>&1
done

exit 0
