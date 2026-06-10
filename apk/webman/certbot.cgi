#!/bin/sh
# Certbot CGI

LOG=/tmp/certbot-ui.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === invoked === method=$REQUEST_METHOD qs=$QUERY_STRING len=$CONTENT_LENGTH" >> "$LOG"

BODY=""
if [ "$REQUEST_METHOD" = "POST" ] && [ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
    BODY=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)
fi

ALL_PARAMS="${QUERY_STRING}&${BODY}"

urldecode() {
    echo "$1" | awk 'BEGIN{
        for (i=0; i<256; i++) chr[sprintf("%02X", i)] = sprintf("%c", i)
    }
    {
        gsub(/\+/, " ")
        out = ""
        while (match($0, /%[0-9A-Fa-f][0-9A-Fa-f]/)) {
            out = out substr($0, 1, RSTART-1) chr[toupper(substr($0, RSTART+1, 2))]
            $0 = substr($0, RSTART+RLENGTH)
        }
        print out $0
    }'
}

get_param() {
    raw=$(echo "$ALL_PARAMS" | tr '&' '\n' | grep "^${1}=" | head -1 | cut -d= -f2-)
    urldecode "$raw"
}

ACT=$(get_param act)
TAB=$(get_param tab)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] act=$ACT tab=$TAB" >> "$LOG"

respond() {
    printf 'Content-Type: application/json\r\n\r\n'
    printf '%s' "$1"
}

CFG_DIR="/share/Configuration/certbot"
if [ -n "$APKG_CFG_DIR" ]; then CFG_DIR="$APKG_CFG_DIR"; fi

find_python() {
    for P in python3 python /usr/local/bin/python3 /usr/bin/python3 /usr/bin/python; do
        if command -v "$P" >/dev/null 2>&1; then echo "$P"; return; fi
    done
}

case "$ACT" in

    get)
        PYTHON=$(find_python)
        if [ -z "$PYTHON" ]; then
            respond '{"success":false,"error_code":500,"error_msg":"No python interpreter found"}'
            exit 0
        fi

        case "$TAB" in
            certificate)
                CERT=/usr/builtin/etc/certificate/ssl.crt
                openssl x509 -in "$CERT" -noout -subject -dates > /tmp/certbot-ssl-info.txt 2>&1
                TOKEN=$(cat "${CFG_DIR}/random" 2>/dev/null | tr -d '[:space:]')
                export _TOKEN="$TOKEN"
                RESULT=$("$PYTHON" - << 'PYEOF'
import json, os, re
try:
    with open('/tmp/certbot-ssl-info.txt') as f:
        raw = f.read()
except Exception as e:
    print(json.dumps({'success': False, 'error_msg': str(e)}))
    raise SystemExit
def find(pattern):
    m = re.search(pattern, raw)
    return m.group(1).strip() if m else ''
cn         = find(r'CN\s*=\s*([^,/\n]+)')
not_before = find(r'notBefore=(.+)')
not_after  = find(r'notAfter=(.+)')
token      = os.environ.get('_TOKEN', '')
print(json.dumps({'success': True, 'cn': cn, 'not_before': not_before, 'not_after': not_after, 'token': token}))
PYEOF
)
                printf 'Content-Type: application/json\r\n\r\n'
                printf '%s' "$RESULT"
                ;;

            settings)
                PROVIDER=$(cat "${CFG_DIR}/provider.conf" 2>/dev/null | xargs || echo 'ovh')
                DOMAINS=$(cat "${CFG_DIR}/domains.conf" 2>/dev/null || echo '')
                CMDLINE=$(cat "${CFG_DIR}/cmdline.conf" 2>/dev/null || echo '')
                export _DOMAINS="$DOMAINS" _PROVIDER="$PROVIDER" _CMDLINE="$CMDLINE"
                if [ -f "${CFG_DIR}/${PROVIDER}.conf" ]; then
                    DEFAULT_CMDLINE="--dns-${PROVIDER} --dns-${PROVIDER}-credentials ${CFG_DIR}/${PROVIDER}.conf"
                else
                    DEFAULT_CMDLINE="--dns-${PROVIDER} --dns-${PROVIDER}-credentials ${CFG_DIR}/credentials.conf"
                fi
                export _DEFAULT_CMDLINE="$DEFAULT_CMDLINE"
                # Use provider-specific conf file (e.g. ovh.conf), fallback to credentials.conf
                if [ -f "${CFG_DIR}/${PROVIDER}.conf" ]; then
                    CREDS_FILE="${CFG_DIR}/${PROVIDER}.conf"
                else
                    CREDS_FILE="${CFG_DIR}/credentials.conf"
                fi
                export _CREDS_FILE="$CREDS_FILE"
                RESULT=$("$PYTHON" - << 'PYEOF'
import json, os, re

def read_creds(path, key):
    try:
        with open(path) as f:
            for line in f:
                m = re.match(r'^\s*' + re.escape(key) + r'\s*=\s*(.+)', line)
                if m:
                    return m.group(1).strip()
    except Exception:
        pass
    return ''

domains         = os.environ.get('_DOMAINS', '')
provider        = os.environ.get('_PROVIDER', 'ovh')
cmdline         = os.environ.get('_CMDLINE', '')
default_cmdline = os.environ.get('_DEFAULT_CMDLINE', '')
creds_file      = os.environ.get('_CREDS_FILE', '')

result = {'success': True, 'domains': domains, 'provider': provider,
          'cmdline': cmdline, 'default_cmdline': default_cmdline}

if provider == 'ovh':
    result['ovh_endpoint']           = read_creds(creds_file, 'dns_ovh_endpoint') or 'ovh-eu'
    result['ovh_application_key']    = read_creds(creds_file, 'dns_ovh_application_key')
    result['ovh_application_secret'] = read_creds(creds_file, 'dns_ovh_application_secret')
    result['ovh_consumer_key']       = read_creds(creds_file, 'dns_ovh_consumer_key')

print(json.dumps(result))
PYEOF
)
                printf 'Content-Type: application/json\r\n\r\n'
                printf '%s' "$RESULT"
                ;;

            *)
                respond '{"success":true}'
                ;;
        esac
        ;;

    set)
        case "$TAB" in
            settings)
                DOMAINS=$(get_param domains)
                PROVIDER=$(get_param provider)
                CMDLINE=$(get_param cmdline)
                OVH_ENDPOINT=$(get_param ovh_endpoint)
                OVH_APP_KEY=$(get_param ovh_application_key)
                OVH_APP_SECRET=$(get_param ovh_application_secret)
                OVH_CONSUMER_KEY=$(get_param ovh_consumer_key)
                mkdir -p "$CFG_DIR"
                DOMAINS_NORMALIZED=$(echo "$DOMAINS" | tr ' ' ',')
                printf '%s\n' "$DOMAINS_NORMALIZED" > "${CFG_DIR}/domains.conf"
                printf '%s\n' "$PROVIDER" > "${CFG_DIR}/provider.conf"
                # cmdline.conf: write if non-empty, remove if empty
                if [ -n "$CMDLINE" ]; then
                    printf '%s\n' "$CMDLINE" > "${CFG_DIR}/cmdline.conf"
                else
                    rm -f "${CFG_DIR}/cmdline.conf"
                fi
                # Write provider credentials to <provider>.conf
                if [ "$PROVIDER" = "ovh" ]; then
                    ENDPOINT="${OVH_ENDPOINT:-ovh-eu}"
                    printf '# OVH API credentials used by Certbot\n' > "${CFG_DIR}/ovh.conf"
                    printf 'dns_ovh_endpoint = %s\n' "$ENDPOINT"              >> "${CFG_DIR}/ovh.conf"
                    printf 'dns_ovh_application_key = %s\n' "$OVH_APP_KEY"    >> "${CFG_DIR}/ovh.conf"
                    printf 'dns_ovh_application_secret = %s\n' "$OVH_APP_SECRET" >> "${CFG_DIR}/ovh.conf"
                    printf 'dns_ovh_consumer_key = %s\n' "$OVH_CONSUMER_KEY"  >> "${CFG_DIR}/ovh.conf"
                    chmod 600 "${CFG_DIR}/ovh.conf"
                fi
                # Run pipx inject for the selected provider
                if [ -n "$APKG_PKG_DIR" ] && [ -n "$APKG_PKG_VER" ]; then
                    PKG_SHORT_VER="${APKG_PKG_VER%-*}"
                    export PIPX_HOME=${APKG_PKG_DIR}/letsencrypt
                    export PIPX_BIN_DIR=${PIPX_HOME}/bin
                    ${PIPX_BIN_DIR}/pipx inject -f certbot certbot-dns-${PROVIDER}==${PKG_SHORT_VER} >> "$LOG" 2>&1
                fi
                respond '{"success":true}'
                ;;
            *)
                respond '{"success":true}'
                ;;
        esac
        ;;

    renew)
        if [ -n "$APKG_PKG_DIR" ]; then
            ${APKG_PKG_DIR}/CONTROL/start-stop.sh force-restart >> "$LOG" 2>&1 &
        fi
        respond '{"success":true}'
        ;;

    *)
        respond '{"success":false,"error_code":400,"error_msg":"Unknown action"}'
        ;;
esac
exit 0
