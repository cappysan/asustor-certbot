#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1

# Remove the crontab line
crontab -l | sed '/cappysan-certbot/d' | crontab -

# Remove /usr/builtin/etc/certificate/chain.crt if it's Let's Encrypt
if openssl x509 -noout -text -in /usr/builtin/etc/certificate/chain.crt | grep Issuer | grep -q ISRG; then
  rm -f /usr/builtin/etc/certificate/chain.crt
fi

rm -f /etc/letsencrypt

exit 0
