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
apt-get install -y ca-certificates curl git

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
  sed -n "s/^${name}=//p" .env | head -n 1
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

if [[ ! -f .env ]]; then
  {
    printf 'TZ=%s\n' "${TZ}"
    printf 'PUID=%s\n' "${PUID}"
    printf 'PGID=%s\n' "${PGID}"
    printf 'MEDIA_DIR=%s\n' "${MEDIA_DIR}"
    printf 'RECORDINGS_DIR=%s\n' "${RECORDINGS_DIR}"
    printf 'RENDER_GID=%s\n' "${RENDER_GID}"
    printf 'COMPOSE_FILE=%s\n' "${COMPOSE_FILE}"
    printf '# Camera RTSP password; replace this with the camera password before adding cameras.\n'
    printf 'FRIGATE_RTSP_PASSWORD=%s\n' "${FRIGATE_RTSP_PASSWORD}"
    printf 'FRIGATE_SHM=%s\n' "${FRIGATE_SHM}"
  } >.env
  chmod 600 .env
fi
chown "${PUID}:${PGID}" .env
chmod 600 .env

mkdir -p \
  "${MEDIA_DIR}/movies" \
  "${MEDIA_DIR}/tv" \
  "${MEDIA_DIR}/music" \
  "${MEDIA_DIR}/photos" \
  "${MEDIA_DIR}/home-videos" \
  "${RECORDINGS_DIR}" \
  config/jellyfin \
  config/frigate \
  cache/jellyfin
chown "${PUID}:${PGID}" \
  "${MEDIA_DIR}" \
  "${MEDIA_DIR}/movies" \
  "${MEDIA_DIR}/tv" \
  "${MEDIA_DIR}/music" \
  "${MEDIA_DIR}/photos" \
  "${MEDIA_DIR}/home-videos" \
  "${RECORDINGS_DIR}"
chown -R "${PUID}:${PGID}" config cache

if [[ ! -f config/frigate/config.yml ]]; then
  sed "s/__OPENVINO_DEVICE__/${OPENVINO_DEVICE}/g" config-templates/frigate.yml >config/frigate/config.yml
fi

docker compose pull
docker compose up -d

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

LAN_IP="$(hostname -I | awk '{print $1}')"
if [[ -z "${LAN_IP}" ]]; then
  LAN_IP=localhost
fi
printf 'Jellyfin: http://%s:8096\n' "${LAN_IP}"
printf 'Frigate:  https://%s:8971 (your browser will warn about its self-signed certificate)\n' "${LAN_IP}"

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
