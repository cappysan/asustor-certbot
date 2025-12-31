#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1

# Build the link since it's not present when we install
ln -sf -T $(realpath ./bin/certbot) /usr/bin/certbot

# Rebuild a link from /etc to this app configuration folder
if test ! -e /etc/letsencrypt; then
  mkdir -p ${APKG_CFG_DIR}/letsencrypt
  ln -sf -T ${APKG_CFG_DIR}/letsencrypt /etc/letsencrypt
fi

export HOME=/share/Configuration/certbot

case $1 in
  start)
    touch "${APKG_CFG_DIR}/active"
    ./bin/certbot-renew
    ;;

  stop)
    if test -f "${APKG_CFG_DIR}/active"; then
      rm -f "${APKG_CFG_DIR}/active"
    fi
    ;;

  restart)
    ./CONTROL/start-stop.sh stop
    ./CONTROL/start-stop.sh start
    ;;

  force-restart)
    ./CONTROL/start-stop.sh stop
    touch "${APKG_CFG_DIR}/active"
    ./bin/certbot-renew --force-renewal
    ;;

  *)
    echo "usage: $0 {start|stop|restart|force-restart}"
    exit 1
    ;;

esac
exit 0
