# What to Buy

Prices are US prices I checked on **Nov 21, 2026** (Black Friday week). They change often, so check the link before you buy. SSD, RAM and hard-drive prices are much higher in 2026 than in past years, so this guide keeps what the mini PC ships with and puts the money into hard drives.

## The short version

| Tier | Good for | Approx. total |
| --- | --- | --- |
| **Starter** | 1 camera, a few hundred movies | **~$902** |
| **Recommended** | 1 camera, big library | **~$1,293** |
| **UniFi** (you already have a UDM Pro) | 1 UniFi camera recorded by Protect, with Frigate AI on top, big library, rack | **~$1,600–1,625** |
| **Pro** | 1 premium night-vision camera, huge library, several people streaming at once | **~$1,993** |

Every list has **one camera**.

You don't need a monitor or keyboard after setup. Borrow them for the 20 minutes it takes to install Ubuntu.

---

## 1. The mini PC (the server)

Get an **Intel** CPU. Intel's built-in graphics (Quick Sync) lets Jellyfin convert video for phones and TVs without slowing down. The same chip also runs Frigate's person/car detection through OpenVINO, so you don't need a Google Coral.

| Pick | Why | Price | Link |
| --- | --- | --- | --- |
| **Beelink EQ13** (Intel N100, 16 GB, 500 GB) — **recommended** | Frigate's own docs call it their favorite. It has **two Ethernet ports**, so the camera gets its own private network with no internet access. | ~$299 (stock comes and goes) | [Amazon](https://www.amazon.com/dp/B0D66ZFGKB) |
| GMKtec G3 Plus (Intel N150, 8 GB, 256 GB) — budget | Cheapest box that works. It has one Ethernet port and less RAM. Fine for the Starter tier. | $139 | [Amazon](https://www.amazon.com/dp/B0DM58M5SD) |
| **Beelink EQi12** (Core i5-1235U, 16 GB, 500 GB) — Pro | About 3× the CPU power. Handles several 4K streams at once. | $439 | [Amazon](https://www.amazon.com/dp/B0B1B64NKD) |

> **Avoid the Beelink EQ14.** Frigate's [hardware page](https://docs.frigate.video/frigate/hardware) warns it has known compatibility issues. Also avoid AMD mini PCs for this build: Frigate's detection works best on Intel.

## 2. Storage (hard drives)

Two kinds of data go on the drives:

- **Movies/TV** (Jellyfin): a 1080p movie is about 4–10 GB; a 4K movie is about 20–60 GB.
- **Camera recordings** (Frigate): one 5 MP camera recording 24/7 uses roughly **40 GB per day**. One camera for 7 days is about 280 GB. Recording only when there's motion cuts that a lot.

| Item | Use | Price | Link |
| --- | --- | --- | --- |
| **WD Elements 20 TB** USB desktop drive | Simplest: one plug-in drive holds both media and recordings. Best price per TB right now (the 12 TB costs the same). | ~$550 | [Amazon search](https://www.amazon.com/s?k=WD+Elements+20TB+desktop) |
| **TerraMaster D4-320** 4-bay USB-C enclosure | Holds up to 4 bare drives over one USB-C cable (no RAID, every drive shows up separately). | $152 | [B&H](https://www.bhphotovideo.com/c/product/1834179-REG/terramaster_d4_320_4_bay_usb_3_2_gen2.html) · [Amazon](https://www.amazon.com/dp/B0CTTL9R7Z) |
| **Toshiba MG08 16 TB** (refurbished, 2-yr warranty) | Media drive for the enclosure. Datacenter drives tested and resold by ServerPartDeals. Best $/TB. | $399 | [ServerPartDeals](https://serverpartdeals.com/collections/16tb-enterprise-sata-hard-drives) |
| **Seagate SkyHawk 4 TB** (surveillance drive) | Camera recordings. Built for non-stop writing. About 3 months of 24/7 recording for one camera. Also the drive for the UDM Pro bay in the UniFi build. | $160 | [Amazon](https://www.amazon.com/dp/B0B1JPYH2Z) |
| **WD Purple 8 TB** (surveillance drive) | More history: about 6 months of 24/7 recording for one camera. | $375 | [Micro Center](https://www.microcenter.com/product/677532/wd-purple-8tb-5640-rpm-sata-iii-6gb-s-35-surveillance-internal-cmr-hard-drive) |

Keep recordings and movies on **separate drives** when you can, so 24/7 recording never slows down movie playback.

**Backups:** these setups don't back up anything. Keep your irreplaceable stuff (family photos and videos) in a second place too.

## 3. Cameras

Buy one **wired PoE camera**: one Ethernet cable carries both power and video. Skip Wi-Fi cameras, which drop out. Skip cloud-only cameras like Ring, Nest, Blink, Arlo and most Wyze, because they can't stream to Frigate.

| Camera | Notes | Price | Link |
| --- | --- | --- | --- |
| **Reolink RLC-520A** (5 MP dome) | Cheap and reliable. Domes are harder to knock out of position. | $59.49 | [Amazon](https://www.amazon.com/dp/B08LKC9BJ8) |
| **Reolink RLC-510A** (5 MP bullet) | Same camera in a bullet shape. Good for driveways. | $59.49 | [Amazon](https://www.amazon.com/dp/B08F568BH1) |
| **UniFi G5 Bullet** (2K / 4 MP) — UniFi | For UDM Pro owners: recorded by UniFi Protect, and Frigate can watch the same stream. See the [UniFi guide](UNIFI.md). | $129–148 | [UI Store](https://store.ui.com/us/en/products/uvc-g5-bullet) |
| **EmpireTech IPC-T54IR-AS** (4 MP Dahua turret) — Pro | Frigate's top recommendation: big sensor, much better at night. | ~$220 | [EmpireTech](https://empiretech01.com/products/empiretech-ipc-t54ir-as-1-1-8-cmos-4mp-ir-fixed-focal-eyeball-network-camera) · [Amazon](https://www.amazon.com/dp/B07S2196R9) |

> Frigate's docs report problems with Reolink's **4K** models (like the RLC-810A). Stick to 5 MP or lower for Reolink.

## 4. Network gear

| Item | Notes | Price | Link |
| --- | --- | --- | --- |
| **TP-Link TL-PoE150S** PoE injector | Powers the camera over its Ethernet cable. Plug and play. Skip it if you already have a PoE switch. | $15.99 | [Amazon](https://www.amazon.com/dp/B001PS9E5I) |
| **Outdoor Cat6, 100 ft** (UV-resistant, direct burial) | Runs to the camera. Get a shorter cable when the run is shorter. | $53.98 | [Amazon](https://www.amazon.com/dp/B0873WMNPG) |

**Wiring:** camera → PoE injector (or PoE switch) → the mini PC's **second** Ethernet port (EQ13). The mini PC's first port goes to your router. The camera can then talk to Frigate but never reach the internet. If you only have one port, plug the injector into the router and block the camera's internet access in your router settings.

**Have a UniFi Dream Machine Pro?** It has no PoE ports, so you still need the injector above or a PoE switch you already own. Plug it into a UDM Pro port that's set to a camera VLAN. The UDM Pro also makes the second Ethernet port unnecessary and gives you a built-in VPN. See the [UniFi guide](UNIFI.md).

## 5. Power and TV

| Item | Notes | Price | Link |
| --- | --- | --- | --- |
| **APC Back-UPS BE600M1** | Battery backup. Keeps recording through short outages and protects the drives from sudden power loss. | $83.99 | [Amazon](https://www.amazon.com/dp/B01FWAZEIU) |
| **onn 4K Pro** (Google TV) | Cheap 4K streaming box with the official Jellyfin app. Fire TV, Roku, Apple TV and smart TVs also have Jellyfin apps. | $69.98 | [Walmart](https://www.walmart.com/ip/4K-PRO-STREAMING/18382213962) |
| **HDHomeRun Flex Duo** (optional) | Free over-the-air TV from an antenna, shown inside Jellyfin as Live TV with a DVR. | $109.99 | [Amazon](https://www.amazon.com/dp/B092KM482V) |

## 6. Rack (optional)

A UniFi Dream Machine Pro is a full-width 19" rack device (1U, 11.2" deep), so it needs a standard 19" rack. The small 10" "mini racks" are too narrow for it. A 6U wall-mount rack holds everything here and is about 16" tall:

| Item | Notes | Price | Link |
| --- | --- | --- | --- |
| **NavePoint 6U wall-mount rack** (18" deep) | Open frame with a swing-out front, mounts on two wall studs (or sits on a shelf). Cage nuts and screws included. | $157.99 | [Amazon](https://www.amazon.com/dp/B0714JBWMF) |
| **Raising Electronics 1U vented shelf** (12" deep), ×2 | One for the mini PC and USB drive or enclosure, one for the PoE injector or switch. | $23.99 each | [Amazon](https://www.amazon.com/dp/B01M8HKRA7) |
| **VEVOR 1U power strip** (10 outlets, surge protected) | Plug it into the UPS so everything in the rack is on battery. | $44.90 | [VEVOR](https://www.vevor.com/power-strips-c_13422/vevor-19-1u-pdu-10-outlets-rack-mount-power-strip-surge-overload-protection-p_010862059691) |
| **Total** | | **~$251** | |

Suggested layout, top to bottom:

| U | Item |
| --- | --- |
| 1 | UDM Pro |
| 2 | Shelf: PoE injector or switch |
| 3 | (empty, for cable slack or a patch panel later) |
| 4 | Shelf: mini PC and drive |
| 5 | (leave empty above the mini PC for airflow) |
| 6 | Power strip |

The APC UPS isn't rack-mount; set it on the floor under the rack.

---

## Full shopping lists

### Starter (~$902)
| Item | Qty | Cost |
| --- | --- | --- |
| GMKtec G3 Plus | 1 | $139 |
| WD Elements 20 TB | 1 | $550 |
| Reolink RLC-520A | 1 | $59 |
| TP-Link TL-PoE150S injector | 1 | $16 |
| Outdoor Cat6 100 ft | 1 | $54 |
| APC BE600M1 | 1 | $84 |
| **Total** | | **~$902** |

### Recommended (~$1,293)
| Item | Qty | Cost |
| --- | --- | --- |
| Beelink EQ13 | 1 | $299 |
| TerraMaster D4-320 | 1 | $152 |
| Toshiba MG08 16 TB (refurb) | 1 | $399 |
| Seagate SkyHawk 4 TB | 1 | $160 |
| Reolink RLC-520A or 510A | 1 | $59 |
| TP-Link TL-PoE150S injector | 1 | $16 |
| Outdoor Cat6 100 ft | 1 | $54 |
| APC BE600M1 | 1 | $84 |
| onn 4K Pro | 1 | $70 |
| **Total** | | **~$1,293** |

### UniFi build (with a UDM Pro you already own)
About **$1,600–1,625**, not counting the UDM Pro. UniFi Protect records the camera 24/7 to the drive in the UDM Pro bay. Frigate on the mini PC watches the same stream for person/car/animal detection (setup in the [UniFi guide](UNIFI.md#4a-frigate-and-unifi-protect-together)).

| Item | Qty | Cost |
| --- | --- | --- |
| Beelink EQ13 | 1 | $299 |
| TerraMaster D4-320 | 1 | $152 |
| Toshiba MG08 16 TB (refurb), for media | 1 | $399 |
| UniFi G5 Bullet | 1 | $129–148 |
| Seagate SkyHawk 4 TB, in the UDM Pro bay | 1 | $160 |
| PoE: your TP-Link PoE switch, or a UniFi U-POE-af injector | 1 | $0–8 |
| Outdoor Cat6 100 ft | 1 | $54 |
| 6U rack + 2 shelves + power strip ([section 6](#6-rack-optional)) | 1 | $251 |
| APC BE600M1 | 1 | $84 |
| onn 4K Pro | 1 | $70 |
| **Total** | | **~$1,600–1,625** |

### Pro (~$1,993)
| Item | Qty | Cost |
| --- | --- | --- |
| Beelink EQi12 (i5) | 1 | $439 |
| TerraMaster D4-320 | 1 | $152 |
| Toshiba MG08 16 TB (refurb) | 2 | $798 |
| Seagate SkyHawk 4 TB | 1 | $160 |
| EmpireTech IPC-T54IR-AS | 1 | $220 |
| TP-Link TL-PoE150S injector | 1 | $16 |
| Outdoor Cat6 100 ft | 1 | $54 |
| APC BE600M1 | 1 | $84 |
| onn 4K Pro | 1 | $70 |
| **Total** | | **~$1,993** |

---

## Software (all free)

| Software | What it does | Link |
| --- | --- | --- |
| **Ubuntu Server 24.04 LTS** | The operating system. Wipe the Windows that ships on the mini PC and install this. | [ubuntu.com/download/server](https://ubuntu.com/download/server) |
| **Docker** | Runs each app in its own container. The installer sets it up for you. | [docker.com](https://www.docker.com/) |
| **Jellyfin** | Your own Netflix: movies, TV, music, photos and live TV. No account or subscription. | [jellyfin.org](https://jellyfin.org/) |
| **Frigate** | Camera recorder (NVR) with AI person/car/animal detection that runs locally. | [frigate.video](https://frigate.video/) |
| **Homepage** | The dashboard on port 3000, with a clickable tile and live status for each app. | [gethomepage.dev](https://gethomepage.dev/) |
| **Tailscale** (optional) | Secure remote access from your phone without opening ports on your router. Free for personal use. | [tailscale.com](https://tailscale.com/) |
| **balenaEtcher** | Writes the Ubuntu installer to a USB stick (you'll need an 8 GB+ stick). | [etcher.balena.io](https://etcher.balena.io/) |

### Why Ubuntu and not Proxmox?
Proxmox turns the mini PC into a host for virtual machines. That's great if you want to run lots of separate systems, but it adds a layer: you'd have to pass the Intel graphics chip through to a VM or container before Jellyfin and Frigate could use it, and that's the most common thing to break. On a single small box, plain Ubuntu plus Docker is simpler, faster, and what the one-line installer expects. You can always move to Proxmox later. The `config/` folder and your drives move over as-is.

### What about Kubernetes?
Not for this. Kubernetes is built to spread apps across many servers and restart them on another machine when one dies. On a single mini PC there's nowhere else to move them, so you'd get extra moving parts and lose 1–2 GB of RAM that Frigate could use. Docker Compose (what this repo uses) is the right tool for one box.

## Installing Ubuntu (one time)
1. On another computer, download Ubuntu Server 24.04 LTS and flash it to a USB stick with balenaEtcher.
2. Plug the stick, a monitor, a keyboard and Ethernet into the mini PC. Power on and tap **F7** (Beelink boot menu; on other brands try F12, F11 or Esc). Pick the USB stick.
3. Follow the installer. Use the whole internal SSD, turn on **Install OpenSSH server**, and remember your username and password.
4. After it reboots, log in and run the one-liner from the [README](README.md).
