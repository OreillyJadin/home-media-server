# Home Media Server

A simple Docker setup for a home media library with Jellyfin and Frigate, plus optional apps for photos, audiobooks and e-books. It is designed for Ubuntu Server 24.04 on a small Intel mini PC. You do not need to know Docker to get started.

- **What to buy (with prices):** [BUYING_GUIDE.md](BUYING_GUIDE.md)
- **Getting movies onto it (legal sources):** [MEDIA_GUIDE.md](MEDIA_GUIDE.md)
- **Have a UniFi Dream Machine Pro?** [UNIFI.md](UNIFI.md): camera VLAN, built-in VPN, UniFi Protect vs Frigate

## Install

1. Install Ubuntu Server 24.04 on the mini PC ([steps](BUYING_GUIDE.md#installing-ubuntu-one-time)).
2. If you use an external drive, set it up first ([Using an external drive](#using-an-external-drive)).
3. Log in to the server and run:

```bash
curl -fsSL https://raw.githubusercontent.com/OreillyJadin/home-media-server/main/install.sh | sudo bash
```

The installer asks where to store media and recordings, installs Docker if needed, downloads the services, and prints the addresses and Frigate's first-time admin password. Press Enter to accept each default.

To skip the prompts, pass settings as variables:

```bash
curl -fsSL https://raw.githubusercontent.com/OreillyJadin/home-media-server/main/install.sh \
  | sudo NONINTERACTIVE=1 MEDIA_DIR=/mnt/storage/media RECORDINGS_DIR=/mnt/storage/recordings bash
```

Running the installer again is safe: it keeps your existing `.env` and Frigate `config.yml`. Homepage templates are copied only when missing; to get new dashboard tiles on an existing install, delete `config/homepage/services.yaml` and `config/homepage/settings.yaml`, then rerun the installer.

## Using an external drive

Do this **before** running the installer. Formatting erases the drive.

```bash
lsblk                                   # find the drive, e.g. /dev/sdb (check the size!)
sudo mkfs.ext4 -L storage /dev/sdb      # ERASES /dev/sdb
sudo mkdir -p /mnt/storage
echo 'LABEL=storage /mnt/storage ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo mount -a && df -h /mnt/storage
```

Then install with `MEDIA_DIR=/mnt/storage/media` and `RECORDINGS_DIR=/mnt/storage/recordings` (type them at the prompts, or pass them as shown above). With two drives, mount each one (e.g. `/mnt/media` and `/mnt/recordings`) and point each setting at its own drive.

## What you need

- Ubuntu Server 24.04 (or a Debian-based system with `apt`)
- An Intel N100/N150-class mini PC with at least 8 GB RAM and enough storage for your media and camera recordings (see the [buying guide](BUYING_GUIDE.md))
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
   sudo nano /opt/home-media-server/config/frigate/config.yml
   mediactl restart frigate
   ```

   Put the camera password in `/opt/home-media-server/.env` as `FRIGATE_RTSP_PASSWORD` so the `{FRIGATE_RTSP_PASSWORD}` placeholder in the config fills in automatically. Keep the value in single quotes, e.g. `FRIGATE_RTSP_PASSWORD='my$ecret'`. After changing `.env`, run `mediactl start` to apply it (a plain restart does not reload `.env`).

   Example RTSP addresses:

   ```text
   Reolink main: rtsp://admin:CAMERA_PASSWORD@192.168.1.50:554/h264Preview_01_main
   Reolink sub:  rtsp://admin:CAMERA_PASSWORD@192.168.1.50:554/h264Preview_01_sub
   Amcrest:      rtsp://admin:CAMERA_PASSWORD@192.168.1.60:554/cam/realmonitor?channel=1&subtype=0
   Dahua:        rtsp://admin:CAMERA_PASSWORD@192.168.1.70:554/cam/realmonitor?channel=1&subtype=0
   ```

   For Reolink cameras at 5MP or lower, Frigate recommends the HTTP-FLV main stream for reliability; see the [Reolink camera configuration guide](https://docs.frigate.video/configuration/camera_specific#reolink-cameras). Some newer high-resolution models need different stream settings, so check that guide before choosing a camera.

4. Open Immich at `http://SERVER-IP:2283` and create the administrator account on first visit.
5. Open Audiobookshelf at `http://SERVER-IP:13378` to create its initial account.
6. Open Calibre-Web at `http://SERVER-IP:8083` and sign in as `admin` with the password printed by the installer or shown by `mediactl password`. You can change it in your profile.

## Dashboard

Open `http://SERVER-IP:3000` for the dashboard. Its tiles link to Jellyfin, Frigate, Immich, Audiobookshelf, Calibre-Web and your router; service tiles show live status dots.

To enable the Jellyfin widget, create an API key in Jellyfin under **Dashboard → API Keys**, paste it into `config/homepage/services.yaml`, and run `mediactl restart homepage`.

If Homepage shows **Host validation failed**, add the address you are using (including `:3000`) to `HOMEPAGE_ALLOWED_HOSTS` in `.env`, separated by commas with no spaces, then run `mediactl start`.

## Photos (Immich)

Install the Immich phone app and enable automatic backup to upload photos to your server. On first visit, create the administrator account. To include your existing photos, open **Administration → Libraries**, add an External Library, and set its path to `/mnt/photos`. The machine-learning service can use about 1–2 GB of RAM; on an 8 GB system, remove `photos` from `COMPOSE_PROFILES` in `.env` and run `mediactl start` if you need to reduce memory use.

## Audiobooks (Audiobookshelf)

Organize audiobooks as `Author/Book Title/files` under `/srv/media/audiobooks` (or your chosen media directory). Put podcasts under `/srv/media/podcasts`. The Audiobookshelf phone app can connect to `http://SERVER-IP:13378` for listening and downloads.

## E-books and Kindle (Calibre-Web)

Sign in as `admin` with the password printed by the installer or shown by `mediactl password`. You can change it in your profile.

1. In Calibre-Web, open **Admin → Basic Configuration** and set the Calibre Library path to `/books`, then save. The installer creates a blank Calibre library there.
2. In **Admin → Basic Configuration**, enable uploads if you want to add books through the browser.
3. Open **Admin → Edit Email Server Settings** and configure Gmail:
   - SMTP server: `smtp.gmail.com`
   - Port: `587`
   - Encryption: STARTTLS
   - Username: your Gmail address
   - Password: a Gmail app password
4. In Amazon **Manage Your Content and Devices → Preferences → Personal Document Settings**, add your Gmail sender address to the **Approved Personal Document E-mail List**.
5. In Calibre-Web, open your user profile and enter your Kindle email address.
6. Open a book and choose **Send to Kindle**. EPUB files work.

To disable Audiobookshelf and Calibre-Web, remove `books` from `COMPOSE_PROFILES` in `.env` and run `mediactl start`.

## Remote access

If you have a UniFi Dream Machine Pro, its built-in Teleport/WireGuard VPN does this without Tailscale ([UNIFI.md](UNIFI.md#3-remote-access-without-opening-ports)).

Otherwise, use [Tailscale](https://tailscale.com/) rather than opening ports on your router. The installer offers to install it (default: No). To add it later:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Install the Tailscale app on your phone with the same account, then open `http://SERVER-TAILSCALE-IP:8096` (Jellyfin), `https://SERVER-TAILSCALE-IP:8971` (Frigate), `http://SERVER-TAILSCALE-IP:2283` (Immich), `http://SERVER-TAILSCALE-IP:13378` (Audiobookshelf), `http://SERVER-TAILSCALE-IP:8083` (Calibre-Web), or `http://SERVER-TAILSCALE-IP:3000` (dashboard) from anywhere. `tailscale ip -4` on the server shows that address.

## Security and networking

- Change default camera passwords, and use a unique password for each camera.
- Put the camera on an isolated network/VLAN and block its internet access in your router where possible ([UniFi steps](UNIFI.md#2-put-the-camera-on-its-own-network-vlan)).
- **Dual-NIC tip:** with a dual-Ethernet mini PC such as the Beelink EQ13, connect the second Ethernet port to the camera's PoE injector or switch. This keeps the camera from reaching the internet.
- Port 8554 (raw RTSP restreams) is not published because it has no login. Only add it if another app such as Home Assistant needs it, and add RTSP credentials in go2rtc first.
- Do not forward Jellyfin or Frigate ports directly to the public internet.
- Frigate's example camera is disabled until you configure it. Replace the sample credentials and addresses before enabling it.
- Jellyfin and Frigate are available to devices on your local network; secure your server and network accordingly.

## Files and folders

```text
.
├── .env                         # Your local settings and passwords
├── cache/                       # Jellyfin and Immich temporary caches
├── config/
│   ├── audiobookshelf/          # Audiobookshelf settings and metadata
│   ├── calibre-web/             # E-book server settings
│   ├── homepage/                # Dashboard services, settings, widgets and bookmarks
│   ├── frigate/config.yml       # Frigate settings and camera setup
│   └── jellyfin/                # Jellyfin settings
├── db/immich/                   # Immich database; kept by uninstall unless purged
├── docker-compose.yml           # Services without optional GPU devices
├── docker-compose.gpu.yml       # Optional Intel graphics devices
├── mediactl                     # Service management helper
└── config-templates/            # Starter Frigate and Homepage configurations
```

Media is stored in `/srv/media` and Frigate recordings in `/srv/recordings` by default. The installer creates them; you can choose other directories during setup. Optional photos, books, and audiobook services are enabled by the `photos,books` Compose profiles in `.env`.

## `mediactl` commands

`mediactl` asks for your password (sudo) when needed.

```text
mediactl status             Show service status
mediactl logs [service]     Follow logs (for example: mediactl logs frigate)
mediactl restart [service]  Restart a service (for example: immich-server)
mediactl update             Pull updates and restart enabled services
mediactl stop               Stop enabled services
mediactl start              Start enabled services
mediactl password           Show Frigate and Calibre-Web admin passwords
mediactl uninstall          Stop/remove containers; keep your data
mediactl uninstall --purge  Also delete media, recordings and app data after confirmation
```

## Troubleshooting

- **No GPU acceleration:** run `ls -l /dev/dri`. If it is missing, make sure the host has Intel graphics drivers enabled. The stack still runs, but Jellyfin hardware transcoding is off.
- **Frigate won't start:** inspect `mediactl logs frigate` and check your configuration file for a typo. The starter camera is disabled until you edit it.
- **Disk is filling up:** check free space with `df -h`. Camera recordings can use a lot of space; change Frigate's retention in `config/frigate/config.yml` or move `/srv/recordings` to a larger drive.
- **Camera stream is unavailable:** confirm the camera address, username, password and stream path, and make sure the camera network is reachable from the server.

## More information

- [Buying guide](BUYING_GUIDE.md): hardware with prices
- [Media guide](MEDIA_GUIDE.md): getting content legally and naming files
- [UniFi guide](UNIFI.md): UDM Pro network setup and UniFi Protect
- [Why not Kubernetes or Proxmox?](BUYING_GUIDE.md#what-about-kubernetes)
- [Frigate documentation](https://docs.frigate.video/)
- [Jellyfin documentation](https://jellyfin.org/docs/)
