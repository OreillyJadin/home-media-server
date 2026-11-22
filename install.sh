#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Please run as root, for example: curl -fsSL URL/install.sh | sudo bash\n' >&2
  exit 1
fi

if [[ "$(uname -s)" != Linux ]]; then
  printf 'This installer requires Linux.\n' >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  printf 'This installer requires apt-get.\n' >&2
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != ubuntu && "${ID_LIKE:-}" != *debian* ]]; then
    printf 'Warning: this is not Ubuntu or a Debian-like system; continuing with apt.\n' >&2
  fi
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl git openssl

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker
if ! docker compose version >/dev/null 2>&1; then
  if ! apt-get install -y docker-compose-plugin; then
    apt-get install -y docker-compose-v2 || true
  fi
fi
if ! docker compose version >/dev/null 2>&1; then
  printf 'Docker Compose v2 is required (docker compose). Install it and rerun.\n' >&2
  exit 1
fi

SCRIPT_DIR=""
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
is_install_checkout() {
  local directory="$1"
  [[ -f "${directory}/docker-compose.yml" &&
    -f "${directory}/config-templates/frigate.yml" &&
    -f "${directory}/mediactl" ]]
}

if [[ -f "${SCRIPT_PATH}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${SCRIPT_PATH}")" && pwd)"
fi
if [[ -n "${SCRIPT_DIR}" ]] && ! is_install_checkout "${SCRIPT_DIR}"; then
  SCRIPT_DIR=""
fi
if is_install_checkout "$(pwd)"; then
  SCRIPT_DIR="$(pwd)"
fi

INSTALL_DIR="${INSTALL_DIR:-/opt/home-media-server}"
if [[ -n "${SCRIPT_DIR}" ]]; then
  INSTALL_DIR="${SCRIPT_DIR}"
else
  if [[ -d "${INSTALL_DIR}/.git" ]]; then
    git -C "${INSTALL_DIR}" pull --ff-only
  elif [[ -e "${INSTALL_DIR}" ]]; then
    printf 'Install directory exists but is not a Git checkout: %s\n' "${INSTALL_DIR}" >&2
    exit 1
  else
    git clone --branch "${BRANCH:-main}" --depth 1 "${REPO_URL:-https://github.com/OreillyJadin/home-media-server.git}" "${INSTALL_DIR}"
  fi
fi
cd "${INSTALL_DIR}"

OWNER_USER="${SUDO_USER:-}"
if [[ -n "${OWNER_USER}" ]] && id "${OWNER_USER}" >/dev/null 2>&1; then
  DEFAULT_PUID="$(id -u "${OWNER_USER}")"
  DEFAULT_PGID="$(id -g "${OWNER_USER}")"
else
  DEFAULT_PUID=1000
  DEFAULT_PGID=1000
fi

DEFAULT_TZ="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
if [[ -z "${DEFAULT_TZ}" ]]; then
  DEFAULT_TZ=America/Chicago
fi

prompt_value() {
  local prompt="$1"
  local default="$2"
  local include_default="${3:-1}"
  local answer=""
  local suffix=" [${default}]"
  if [[ "${include_default}" == 0 ]]; then
    suffix=""
  fi
  if [[ -r /dev/tty ]]; then
    if printf '%s%s: ' "${prompt}" "${suffix}" >/dev/tty 2>/dev/null &&
      IFS= read -r answer </dev/tty 2>/dev/null; then
      :
    fi
  fi
  printf '%s' "${answer:-${default}}"
}

read_env_setting() {
  local name="$1"
  local value
  local first
  local last
  value="$(sed -n "s/^${name}=//p" .env | head -n 1)"
  if (( ${#value} >= 2 )); then
    first="${value:0:1}"
    last="${value:${#value}-1:1}"
    if [[ ( "${first}" == "'" && "${last}" == "'" ) ||
      ( "${first}" == '"' && "${last}" == '"' ) ]]; then
      value="${value:1:${#value}-2}"
    fi
  fi
  printf '%s' "${value}"
}

append_env_setting() {
  local name="$1"
  local value="$2"
  if ! grep -q "^${name}=" .env; then
    printf '%s=%s\n' "${name}" "${value}" >>.env
    printf 'Added %s to .env.\n' "${name}"
  fi
}

if [[ -f .env ]]; then
  printf 'Keeping existing .env settings.\n'
  TZ="$(read_env_setting TZ)"
  MEDIA_DIR="$(read_env_setting MEDIA_DIR)"
  RECORDINGS_DIR="$(read_env_setting RECORDINGS_DIR)"
  PUID="$(read_env_setting PUID)"
  PGID="$(read_env_setting PGID)"
  RENDER_GID="$(read_env_setting RENDER_GID)"
  COMPOSE_FILE="$(read_env_setting COMPOSE_FILE)"
  FRIGATE_RTSP_PASSWORD="$(read_env_setting FRIGATE_RTSP_PASSWORD)"
  FRIGATE_SHM="$(read_env_setting FRIGATE_SHM)"
  COMPOSE_PROFILES="$(read_env_setting COMPOSE_PROFILES)"
  IMMICH_UPLOAD_DIR="$(read_env_setting IMMICH_UPLOAD_DIR)"
  IMMICH_DB_PASSWORD="$(read_env_setting IMMICH_DB_PASSWORD)"
else
  if [[ "${NONINTERACTIVE:-0}" != 1 ]]; then
    if [[ -z "${TZ+x}" ]]; then
      TZ="$(prompt_value 'Timezone' "${DEFAULT_TZ}")"
    fi
    if [[ -z "${MEDIA_DIR+x}" ]]; then
      MEDIA_DIR="$(prompt_value 'Media directory' '/srv/media')"
    fi
    if [[ -z "${RECORDINGS_DIR+x}" ]]; then
      RECORDINGS_DIR="$(prompt_value 'Recordings directory' '/srv/recordings')"
    fi
  fi

  TZ="${TZ:-${DEFAULT_TZ}}"
  MEDIA_DIR="${MEDIA_DIR:-/srv/media}"
  RECORDINGS_DIR="${RECORDINGS_DIR:-/srv/recordings}"
  PUID="${PUID:-${DEFAULT_PUID}}"
  PGID="${PGID:-${DEFAULT_PGID}}"
  FRIGATE_RTSP_PASSWORD="${FRIGATE_RTSP_PASSWORD:-changeme}"
  FRIGATE_SHM="${FRIGATE_SHM:-512mb}"
fi

if [[ -e /dev/dri/renderD128 ]]; then
  RENDER_GID="${RENDER_GID:-$(stat -c '%g' /dev/dri/renderD128)}"
  COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml:docker-compose.gpu.yml}"
  OPENVINO_DEVICE=GPU
else
  RENDER_GID="${RENDER_GID:-44}"
  COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
  OPENVINO_DEVICE=CPU
  printf 'Warning: /dev/dri/renderD128 was not found. Hardware video transcoding is off; Frigate detection will use the CPU.\n'
fi

LAN_IP="$(hostname -I | awk '{print $1}')"
if [[ -z "${LAN_IP}" ]]; then
  LAN_IP=localhost
fi
GATEWAY_IP="$(ip route | awk '/^default/ {print $3; exit}' || true)"
if [[ -z "${GATEWAY_IP}" ]]; then
  GATEWAY_IP=192.168.1.1
fi

if [[ ! -f .env ]]; then
  if [[ "${FRIGATE_RTSP_PASSWORD}" == *"'"* ]]; then
    printf 'FRIGATE_RTSP_PASSWORD must not contain a single quote.\n' >&2
    exit 1
  fi
  {
    printf 'TZ=%s\n' "${TZ}"
    printf 'PUID=%s\n' "${PUID}"
    printf 'PGID=%s\n' "${PGID}"
    printf 'MEDIA_DIR=%s\n' "${MEDIA_DIR}"
    printf 'RECORDINGS_DIR=%s\n' "${RECORDINGS_DIR}"
    printf 'RENDER_GID=%s\n' "${RENDER_GID}"
    printf 'COMPOSE_FILE=%s\n' "${COMPOSE_FILE}"
    printf '# Camera RTSP password; replace this with the camera password before adding the camera.\n'
    printf "FRIGATE_RTSP_PASSWORD='%s'\n" "${FRIGATE_RTSP_PASSWORD}"
    printf 'FRIGATE_SHM=%s\n' "${FRIGATE_SHM}"
  } >.env
  chmod 600 .env
fi

if ! grep -q '^COMPOSE_PROFILES=' .env; then
  COMPOSE_PROFILES=photos,books
fi
if ! grep -q '^IMMICH_UPLOAD_DIR=' .env; then
  IMMICH_UPLOAD_DIR="${MEDIA_DIR}/immich"
fi
if ! grep -q '^IMMICH_DB_PASSWORD=' .env; then
  IMMICH_DB_PASSWORD="$(openssl rand -hex 16)"
fi
append_env_setting HOMEPAGE_ALLOWED_HOSTS "${LAN_IP}:3000,localhost:3000"
append_env_setting COMPOSE_PROFILES "${COMPOSE_PROFILES}"
append_env_setting IMMICH_UPLOAD_DIR "${IMMICH_UPLOAD_DIR}"
append_env_setting IMMICH_DB_PASSWORD "${IMMICH_DB_PASSWORD}"

if [[ -z "${IMMICH_UPLOAD_DIR}" ]]; then
  printf 'IMMICH_UPLOAD_DIR in .env must not be empty.\n' >&2
  exit 1
fi
if [[ -z "${IMMICH_DB_PASSWORD}" ]]; then
  printf 'IMMICH_DB_PASSWORD in .env must not be empty.\n' >&2
  exit 1
fi
chown "${PUID}:${PGID}" .env
chmod 600 .env

mkdir -p \
  "${MEDIA_DIR}/movies" \
  "${MEDIA_DIR}/tv" \
  "${MEDIA_DIR}/music" \
  "${MEDIA_DIR}/photos" \
  "${MEDIA_DIR}/home-videos" \
  "${MEDIA_DIR}/audiobooks" \
  "${MEDIA_DIR}/podcasts" \
  "${MEDIA_DIR}/books" \
  "${MEDIA_DIR}/immich" \
  "${IMMICH_UPLOAD_DIR}" \
  "${RECORDINGS_DIR}" \
  config/jellyfin \
  config/frigate \
  config/homepage \
  config/audiobookshelf/config \
  config/audiobookshelf/metadata \
  config/calibre-web \
  cache/jellyfin \
  cache/immich-ml \
  db/immich
chown "${PUID}:${PGID}" \
  "${MEDIA_DIR}" \
  "${MEDIA_DIR}/movies" \
  "${MEDIA_DIR}/tv" \
  "${MEDIA_DIR}/music" \
  "${MEDIA_DIR}/photos" \
  "${MEDIA_DIR}/home-videos" \
  "${MEDIA_DIR}/audiobooks" \
  "${MEDIA_DIR}/podcasts" \
  "${MEDIA_DIR}/books" \
  "${MEDIA_DIR}/immich" \
  "${IMMICH_UPLOAD_DIR}" \
  "${RECORDINGS_DIR}"

CALIBRE_LIBRARY_DB="${MEDIA_DIR}/books/metadata.db"
CALIBRE_LIBRARY_DB_READY=1
if [[ ! -f "${CALIBRE_LIBRARY_DB}" ]]; then
  CALIBRE_LIBRARY_DB_TMP="${CALIBRE_LIBRARY_DB}.tmp.$$"
  if ! curl -fsSL \
    'https://raw.githubusercontent.com/janeczku/calibre-web/79d35711d73491881ecd2b13ded02c277543dbcb/library/metadata.db' \
    -o "${CALIBRE_LIBRARY_DB_TMP}"; then
    rm -f -- "${CALIBRE_LIBRARY_DB_TMP}"
    printf 'WARNING: Could not download the blank Calibre library database; add a Calibre library before using Calibre-Web.\n' >&2
    CALIBRE_LIBRARY_DB_READY=0
  else
    mv -- "${CALIBRE_LIBRARY_DB_TMP}" "${CALIBRE_LIBRARY_DB}"
  fi
fi
if [[ "${CALIBRE_LIBRARY_DB_READY}" == 1 ]]; then
  chown "${PUID}:${PGID}" "${CALIBRE_LIBRARY_DB}"
fi

if [[ ! -f config/frigate/config.yml ]]; then
  sed "s/__OPENVINO_DEVICE__/${OPENVINO_DEVICE}/g" config-templates/frigate.yml >config/frigate/config.yml
fi

for template in config-templates/homepage/*.yaml; do
  target="config/homepage/$(basename "${template}")"
  if [[ ! -f "${target}" ]]; then
    sed \
      -e "s|__LAN_IP__|${LAN_IP}|g" \
      -e "s|__GATEWAY_IP__|${GATEWAY_IP}|g" \
      "${template}" >"${target}"
  fi
done

chown -R "${PUID}:${PGID}" config cache

ACTIVE_PROFILES="$(read_env_setting COMPOSE_PROFILES)"
unset COMPOSE_PROFILES IMMICH_UPLOAD_DIR IMMICH_DB_PASSWORD
CALIBRE_DB_EXISTED=0
if [[ -f config/calibre-web/app.db ]]; then
  CALIBRE_DB_EXISTED=1
fi
docker compose pull
docker compose up -d

CALIBRE_ADMIN_PASSWORD="$(read_env_setting CALIBRE_ADMIN_PASSWORD)"
if [[ ",${ACTIVE_PROFILES//[[:space:]]/}," == *",books,"* ]] &&
  { ! grep -q '^CALIBRE_ADMIN_PASSWORD=' .env || [[ "${CALIBRE_DB_EXISTED}" == 0 ]]; }; then
  CALIBRE_ADMIN_PASSWORD="$(openssl rand -hex 12)"
  CALIBRE_ADMIN_PASSWORD+="1aA!"
  printf 'Waiting for Calibre-Web to create its database'
  for _ in $(seq 1 18); do
    if [[ -f config/calibre-web/app.db ]]; then
      break
    fi
    printf '.'
    sleep 5
  done
  printf '\n'
  if [[ -f config/calibre-web/app.db ]] &&
    docker exec --user abc calibre-web /lsiopy/bin/python3 /app/calibre-web/cps.py \
      -p /config/app.db -o /config/calibre-web.log -s "admin:${CALIBRE_ADMIN_PASSWORD}"; then
    CALIBRE_ENV_UID="$(stat -c '%u' .env)"
    CALIBRE_ENV_GID="$(stat -c '%g' .env)"
    CALIBRE_ENV_MODE="$(stat -c '%a' .env)"
    sed -i '/^CALIBRE_ADMIN_PASSWORD=/d' .env
    printf 'CALIBRE_ADMIN_PASSWORD=%s\n' "${CALIBRE_ADMIN_PASSWORD}" >>.env
    chown "${CALIBRE_ENV_UID}:${CALIBRE_ENV_GID}" .env
    chmod "${CALIBRE_ENV_MODE}" .env
  else
    CALIBRE_ADMIN_PASSWORD=""
    printf 'WARNING: Calibre-Web automatic password setup failed. Change the default admin/admin123 password now.\n' >&2
  fi
fi

printf 'Waiting for Frigate to create its admin password'
PASSWORD_LINE=""
for _ in $(seq 1 24); do
  PASSWORD_LINE="$(docker logs frigate 2>&1 | grep -Ei 'Password:' | tail -n 1 || true)"
  if [[ -n "${PASSWORD_LINE}" ]]; then
    break
  fi
  printf '.'
  sleep 5
done
printf '\n'
if [[ -n "${PASSWORD_LINE}" ]]; then
  printf 'Frigate first-boot admin credentials: %s\n' "${PASSWORD_LINE}"
else
  printf 'Frigate has not logged its first-boot password yet. Check it with: mediactl logs frigate\n'
fi

printf 'Dashboard: http://%s:3000\n' "${LAN_IP}"
printf 'Jellyfin: http://%s:8096\n' "${LAN_IP}"
printf 'Frigate:  https://%s:8971 (your browser will warn about its self-signed certificate)\n' "${LAN_IP}"
if [[ ",${ACTIVE_PROFILES//[[:space:]]/}," == *",photos,"* ]]; then
  printf 'Immich: http://%s:2283\n' "${LAN_IP}"
fi
if [[ ",${ACTIVE_PROFILES//[[:space:]]/}," == *",books,"* ]]; then
  printf 'Audiobookshelf: http://%s:13378\n' "${LAN_IP}"
  if [[ -n "${CALIBRE_ADMIN_PASSWORD}" ]]; then
    printf 'Calibre-Web: http://%s:8083 (login admin / %s)\n' "${LAN_IP}" "${CALIBRE_ADMIN_PASSWORD}"
  else
    printf 'Calibre-Web: http://%s:8083 (change the default admin/admin123 password immediately)\n' "${LAN_IP}"
  fi
fi

ln -sfn "${INSTALL_DIR}/mediactl" /usr/local/bin/mediactl
chmod +x install.sh mediactl

INSTALL_TAILSCALE="${INSTALL_TAILSCALE:-}"
if [[ "${NONINTERACTIVE:-0}" != 1 && -z "${INSTALL_TAILSCALE}" ]]; then
  INSTALL_TAILSCALE="$(prompt_value 'Install Tailscale for remote access? (y/N)' 'N' 0)"
fi
case "${INSTALL_TAILSCALE,,}" in
  y|yes|1)
  curl -fsSL https://tailscale.com/install.sh | sh
  tailscale up
    ;;
esac

printf 'Manage the stack with: sudo mediactl status\n'
