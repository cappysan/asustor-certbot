#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
# ------------------------------------------------------------------------------
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1
if test -f ${APKG_PKG_DIR}/env; then
  . ${APKG_PKG_DIR}/env
fi

# Build the link since it's not present when we install
ln -sf -T $(realpath ./letsencrypt/bin/certbot) /usr/bin/certbot

# Rebuild a link from /etc to this app configuration folder
if test ! -e /etc/letsencrypt; then
  mkdir -p ${APKG_CFG_DIR}/letsencrypt
  ln -sf -T ${APKG_CFG_DIR}/letsencrypt /etc/letsencrypt
fi
# ------------------------------------------------------------------------------

case $1 in
  start)
    logger "[${WHAT}] Starting certbot..."
    touch "${APKG_PKG_DIR}/active"
    ./CONTROL/start-hook.sh
    ./CONTROL/certbot-renew
    ;;

  stop)
    logger "[${WHAT}] Stopping certbot..."
    rm -f "${APKG_PKG_DIR}/active"
    ;;

  restart)
    ./CONTROL/start-stop.sh stop
    ./CONTROL/start-stop.sh start
    ;;

  reload)
    if test -f "${APKG_PKG_DIR}/active"; then
      ./CONTROL/start-stop.sh start
    else
      logger "[${WHAT}] Service is stopped, cannot reload."
    fi
    ;;

  force-reload)
    if test -f "${APKG_PKG_DIR}/active"; then
      ./CONTROL/start-hook.sh
      ./CONTROL/certbot-renew --force-renewal
    else
      logger "[${WHAT}] Service is stopped, cannot reload."
    fi
    ;;

  force-restart)
    logger "[Certbot] Restarting certbot [force]..."
    touch "${APKG_PKG_DIR}/active"
    ./CONTROL/start-hook.sh
    ./CONTROL/certbot-renew --force-renewal
    ;;

  *)
    echo "usage: $0 {start|stop|restart|force-restart|force-reload|reload}"
    exit 1
    ;;
esac

exit 0
