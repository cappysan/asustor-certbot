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
ln -sf -T $(realpath ./letsencrypt/bin/certbot) /usr/bin/certbot

# Rebuild a link from /etc to this app configuration folder
if test ! -e /etc/letsencrypt; then
  mkdir -p ${APKG_CFG_DIR}/letsencrypt
  ln -sf -T ${APKG_CFG_DIR}/letsencrypt /etc/letsencrypt
fi

export HOME=/share/Configuration/certbot

case $1 in
  start)
    logger "[Certbot] Starting certbot..."
    touch "${APKG_CFG_DIR}/active"
    ./CONTROL/install-hooks
    ./bin/certbot-renew
    ;;

  stop)
    logger "[Certbot] Stopping certbot..."
    rm -f "${APKG_CFG_DIR}/active"
    ;;

  restart)
    ./CONTROL/start-stop.sh stop
    ./CONTROL/start-stop.sh start
    ;;

  reload)
    logger "[Certbot] Reloading..."
    if test -f "${APKG_CFG_DIR}/active"; then
      ./CONTROL/start-stop.sh stop
      ./CONTROL/start-stop.sh start
    fi
    ;;

  force-restart)
    logger "[Certbot] Restarting certbot [force]..."
    ./CONTROL/start-stop.sh stop
    # Don't call start-stop.sh start because of flag
    touch "${APKG_CFG_DIR}/active"
    ./CONTROL/install-hooks
    ./bin/certbot-renew --force-renewal
    ;;

  *)
    echo "usage: $0 {start|stop|restart|force-restart|reload}"
    exit 1
    ;;

esac
exit 0
