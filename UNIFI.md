# Using a UniFi Dream Machine Pro

The UDM Pro is a great fit for this server. It handles the network side: a fixed IP for the server, a locked-down camera network, and remote access through a VPN. The mini PC runs Jellyfin, Frigate and the dashboard.

Menu names below match recent UniFi Network versions and may differ slightly on yours. Ubiquiti's own guides are linked for each step.

## 1. Give the server a fixed IP
UniFi Network → **Client Devices** → click the mini PC → **Settings** → turn on **Fixed IP Address**. Do this **before** running the installer, because the dashboard links use this IP.

## 2. Put the cameras on their own network (VLAN)
Your cameras then can't reach the internet (no phoning home to the manufacturer), and nothing else on your Wi-Fi can reach them.

1. **Settings → Networks → New Virtual Network**. Name it `Cameras`, use VLAN ID `20`, and let UniFi pick the subnet (for example `192.168.20.0/24`).
2. In the new network's settings, turn **off** internet access for it (option name varies: "Allow Internet Access", or a firewall policy blocking **Cameras → Internet**).
3. Allow the server to reach the cameras: add a firewall policy **allowing** your main network (or just the server's fixed IP) → `Cameras`. Then block everything else into `Cameras` (UniFi's "Isolate Network" option does this on most versions).
4. Get the cameras onto that VLAN in one of two ways:
   - **Cheapest:** keep the TP-Link PoE switch from the [buying guide](BUYING_GUIDE.md). On the UDM Pro, set one LAN port's **Primary (Native) Network** to `Cameras` and plug the TP-Link switch into that port. Every camera on that switch lands on the camera network.
   - **All UniFi:** use a UniFi PoE switch (below) and set each camera port's native network to `Cameras` in UniFi Network.

The Beelink EQ13's second Ethernet port isn't needed with a UDM Pro, because the firewall does the isolation.

If a menu name doesn't match, search the [UniFi Help Center](https://help.ui.com/) for "create virtual network" and "zone-based firewall".

## 3. Remote access without opening ports
The UDM Pro has a built-in VPN, so you can skip Tailscale if you like:
- **Teleport** (easiest): turn it on under **Settings → VPN**, then connect from the free **WiFiman** app on your phone.
- **WireGuard VPN server:** **Settings → VPN → VPN Server → WireGuard**. Create a client and scan its QR code with the WireGuard app.

Once you're connected, open the same addresses you use at home (`http://SERVER-IP:3000` for the dashboard). Still **don't** create port forwards for Jellyfin or Frigate.

## 4. Frigate or UniFi Protect?
The UDM Pro also runs **UniFi Protect**, Ubiquiti's own camera recorder, which records to a 3.5" hard drive in the UDM Pro's drive bay.

| | Frigate (this repo, default) | UniFi Protect on the UDM Pro |
| --- | --- | --- |
| Cameras | Almost any RTSP camera (Reolink, Dahua, Amcrest…) | UniFi cameras. [Third-party ONVIF cameras](https://help.ui.com/hc/en-us/articles/26301104828439-Third-Party-Cameras-in-UniFi-Protect) get live view and playback only |
| Camera cost | ~$60 (Reolink 5 MP) | ~$129–151 (UniFi G5 Bullet / G5 Turret Ultra) |
| AI detection | Person/car/animal detection on the mini PC, zones, masks, review timeline | Built into the newer UniFi cameras |
| App | Web UI (any browser) | Polished UniFi Protect phone app with push notifications |
| Storage | Mini PC's drives | One drive in the UDM Pro bay |

**Recommendation:** if you're starting from zero, use **Frigate with Reolink/Dahua cameras**. It's cheaper per camera and this repo sets it up for you. If you already own UniFi cameras or want the Protect app, use Protect. You can still feed Protect cameras into Frigate for its AI detection:

1. In UniFi Protect, open the camera's settings, find the **RTSP** section (under Advanced on most versions) and enable a stream. Copy the `rtsps://…:7441/…?enableSrtp` link.
2. In `config/frigate/config.yml`, change `rtsps` to `rtspx` and remove `?enableSrtp`:
   ```yaml
   go2rtc:
     streams:
       driveway:
         - rtspx://192.168.1.1:7441/abcdefghijk
   ```
3. Under the camera, add `ffmpeg: { output_args: { record: preset-record-ubiquiti } }`. See [Frigate's UniFi notes](https://docs.frigate.video/configuration/camera_specific#unifi-protect-cameras).

## 5. UniFi gear to buy (only if you want all-UniFi)
Prices are from the official UniFi US store, checked Nov 21, 2026. The range is list price to list price plus Ubiquiti's import surcharge.

| Item | Notes | Price | Link |
| --- | --- | --- | --- |
| **UniFi Switch Lite 8 PoE** (USW-Lite-8-PoE) | 4 PoE+ ports, 52 W. Fine for 4 cameras. Replaces the TP-Link TL-SG1005P | $109–120 | [UI Store](https://store.ui.com/us/en/products/usw-lite-8-poe) |
| **UniFi Ultra 60W** (USW-Ultra-60W) | 7 PoE+ ports, 52 W. Small; good for 5–7 cameras | $159–175 | [UI Store](https://store.ui.com/us/en/products/usw-ultra-60w) |
| **UniFi Switch Lite 16 PoE** (USW-Lite-16-PoE) | 8 PoE+ ports (45 W total) + 8 regular ports | $199–219 | [UI Store](https://store.ui.com/us/en/products/usw-lite-16-poe) |
| **UniFi G5 Bullet** (UVC-G5-Bullet) | 2K (4 MP) camera, for Protect | $129–148 | [UI Store](https://store.ui.com/us/en/products/uvc-g5-bullet) |
| **UniFi G5 Turret Ultra** (UVC-G5-Turret-Ultra) | 2K (4 MP) compact turret, for Protect | $129–151 | [UI Store](https://store.ui.com/us/en/products/uvc-g5-turret-ultra) |
| Drive for the UDM Pro bay | Only if you use Protect. A surveillance drive such as the Seagate SkyHawk 4 TB or WD Purple 8 TB from the [buying guide](BUYING_GUIDE.md#2-storage-hard-drives) | $160–375 | see buying guide |

### Example: one camera recorded by Protect on the UDM Pro
| Item | Price |
| --- | --- |
| UniFi G5 Bullet | $129–148 |
| [Seagate SkyHawk 4 TB](https://www.amazon.com/dp/B0B1JPYH2Z) in the UDM Pro bay | $160 |
| Power: a TP-Link PoE switch you already own, or a [TP-Link TL-PoE150S injector](https://www.amazon.com/dp/B001PS9E5I) | $0–16 |
| [Outdoor Cat6, 100 ft](https://www.amazon.com/dp/B0873WMNPG) | $54 |
| **Total** | **~$343–378** |

The same single camera with a Reolink RLC-510A recorded by Frigate on the mini PC comes to about $113–129, because it doesn't need the UDM drive.
