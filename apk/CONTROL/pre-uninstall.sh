#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1

# Remove the crontab line
crontab -l | sed '/cappysan-certbot/d' | crontab -

exit 0
