#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
. /usr/local/AppCentral/cappysan-certbot/.env.install
cd ${APKG_PKG_DIR:-/nonexistent} || exit 1

function logger() {
  echo "${@}" >&2
  syslog --log 0 --level 0 --user SYSTEM --event "${@}"
}

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
    logger "[Certbot] Starting certbot..."
    ./bin/certbot-renew
    ;;

  stop)
    if test -f "${APKG_CFG_DIR}/active"; then
      rm -f "${APKG_CFG_DIR}/active"
    fi
    logger "[Certbot] Stopping certbot..."
    ;;

  restart)
    ./CONTROL/start-stop.sh stop
    ./CONTROL/start-stop.sh start
    ;;

  reload)
    if test -f "${APKG_CFG_DIR}/active"; then
      ./CONTROL/start-stop.sh stop
      ./CONTROL/start-stop.sh start
    fi
    ;;

  force-restart)
    ./CONTROL/start-stop.sh stop
    touch "${APKG_CFG_DIR}/active"
    logger "[Certbot] Starting certbot [force]..."
    ./bin/certbot-renew --force-renewal
    ;;

  *)
    echo "usage: $0 {start|stop|restart|force-restart|reload}"
    exit 1
    ;;

esac
exit 0
