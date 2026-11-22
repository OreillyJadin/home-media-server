# Home Media Server

A simple Docker setup for a home media library with Jellyfin and Frigate. It is designed for Ubuntu Server 24.04 on a small Intel mini PC. You do not need to know Docker to get started.

## Install

On your Ubuntu Server, run:

```bash
curl -fsSL https://raw.githubusercontent.com/OreillyJadin/home-media-server/main/install.sh | sudo bash
```

The installer asks where to store media and recordings, installs Docker if needed, downloads the services, and prints the addresses and Frigate's first-time admin password. To use the defaults without prompts, set `NONINTERACTIVE=1` and any desired variables before running the installer.

## What you need

- Ubuntu Server 24.04 (or a Debian-based system with `apt`)
- An Intel N100/N150-class mini PC with at least 8 GB RAM and enough storage for your media and camera recordings
- A wired network connection
- A camera that provides an RTSP or supported HTTP stream, if you want to use Frigate

The Intel graphics device (`/dev/dri`) is optional. The installer enables the GPU Compose override automatically when it finds `/dev/dri/renderD128`; without it, Jellyfin hardware transcoding is unavailable and Frigate uses CPU inference. Frigate's hardware guidance currently recommends the Beelink EQ13 (N100, dual Ethernet) as one suitable option.

## After installation

1. Open Jellyfin at `http://SERVER-IP:8096` and follow its setup wizard.
2. Add libraries and point them to the matching folders:
   - Movies: `/media/movies`
   - TV shows: `/media/tv`
   - Music: `/media/music`
   - Photos: `/media/photos`
   - Home videos: `/media/home-videos`
3. Open Frigate at `https://SERVER-IP:8971`. Your browser will show a warning because Frigate uses a self-signed certificate by default. Sign in with the admin password printed by the installer.
4. Add a camera by editing `/opt/home-media-server/config/frigate/config.yml`. Set the camera to `enabled: true`, replace the example address and RTSP password with your camera's details, then run:

   ```bash
   mediactl restart frigate
   ```

   Example RTSP addresses:

   ```text
   Reolink main: rtsp://admin:CAMERA_PASSWORD@192.168.1.50:554/h264Preview_01_main
   Reolink sub:  rtsp://admin:CAMERA_PASSWORD@192.168.1.50:554/h264Preview_01_sub
   Amcrest:      rtsp://admin:CAMERA_PASSWORD@192.168.1.60:554/cam/realmonitor?channel=1&subtype=0
   Dahua:        rtsp://admin:CAMERA_PASSWORD@192.168.1.70:554/cam/realmonitor?channel=1&subtype=0
   ```

   For Reolink cameras at 5MP or lower, Frigate recommends the HTTP-FLV main stream for reliability; see the [Reolink camera configuration guide](https://docs.frigate.video/configuration/camera_specific#reolink-cameras). Some newer high-resolution models need different stream settings, so check that guide before choosing a camera.

## Remote access

For remote access, use [Tailscale](https://tailscale.com/) rather than opening ports on your router. During installation, Tailscale is optional and defaults to No. You can install it later from its official instructions and connect your devices to the same private network.

## Security and networking

- Change default camera passwords, and use a unique password for each camera.
- Put cameras on an isolated network/VLAN and block their internet access in your router where possible.
- **Dual-NIC tip:** with a dual-Ethernet mini PC such as the Beelink EQ13, connect the second Ethernet port to a camera-only network or PoE switch. This can keep cameras from reaching the internet.
- Do not forward Jellyfin or Frigate ports directly to the public internet.
- Frigate's example camera is disabled until you configure it. Replace the sample credentials and addresses before enabling it.
- Jellyfin and Frigate are available to devices on your local network; secure your server and network accordingly.

## Files and folders

```text
.
├── .env                         # Your local settings and passwords
├── cache/jellyfin/              # Jellyfin temporary cache
├── config/
│   ├── frigate/config.yml       # Frigate settings and camera setup
│   └── jellyfin/                # Jellyfin settings
├── docker-compose.yml           # Services without optional GPU devices
├── docker-compose.gpu.yml       # Optional Intel graphics devices
├── mediactl                     # Service management helper
└── config-templates/frigate.yml # Starter Frigate configuration
```

Media is stored in `/srv/media` and Frigate recordings in `/srv/recordings` by default. The installer creates them; you can choose other directories during setup.

## `mediactl` commands

```text
mediactl status             Show service status
mediactl logs [service]     Follow logs (for example: mediactl logs frigate)
mediactl restart [service]  Restart both services or one service
mediactl update             Pull updates and restart the services
mediactl stop               Stop the services
mediactl start              Start the services
mediactl password           Show Frigate's first-boot admin password
mediactl uninstall          Stop/remove containers; keep your data
mediactl uninstall --purge  Also delete media and recordings after confirmation
```

## Troubleshooting

- **No GPU acceleration:** run `ls -l /dev/dri`. If it is missing, make sure the host has Intel graphics drivers enabled. The stack still runs, but Jellyfin hardware transcoding is off.
- **Frigate won't start:** inspect `mediactl logs frigate` and check your configuration file for a typo. The starter camera is disabled until you edit it.
- **Disk is filling up:** check free space with `df -h`. Camera recordings can use a lot of space; change Frigate's retention in `config/frigate/config.yml` or move `/srv/recordings` to a larger drive.
- **Camera stream is unavailable:** confirm the camera address, username, password and stream path, and make sure the camera network is reachable from the server.

## More information

- [Buying guide](BUYING_GUIDE.md) (coming soon)
- [Media guide](MEDIA_GUIDE.md) — getting content (coming soon)
- [Frigate documentation](https://docs.frigate.video/)
- [Jellyfin documentation](https://jellyfin.org/docs/)
