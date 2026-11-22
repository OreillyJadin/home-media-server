# Storage with SnapRAID and mergerfs

The TerraMaster D4-320 is a USB enclosure, not a RAID box: Ubuntu sees each disk separately. SnapRAID uses one disk to hold parity information that can rebuild a failed data disk. mergerfs combines the data disks into one directory, `/srv/media`, which is the Home Media Server's default `MEDIA_DIR`.

SnapRAID runs when you tell it to or on a schedule. It does not protect changes in real time, so files added or changed since the last successful sync are not protected by parity yet. Parity is **not a backup**. Keep family photos, especially Immich uploads, on another device or off-site too. A good target is the 3-2-1 rule: three copies, on two kinds of storage, with one copy off-site.

## Plan the disks

- A parity disk must be at least as large as the largest data disk.
- One parity disk protects against one failed disk.
- In a four-bay D4-320, you can use up to three data disks and one parity disk. Start with one data disk and one parity disk; add later disks as data disks.
- The example below uses one Toshiba MG08 16 TB for data and another as parity. The parity disk is not extra media capacity.

## Set it up

It is easiest to finish these steps **before** running the Home Media Server installer.

1. Connect the D4-320 and identify both drives by size, model, and serial number:

   ```bash
   lsblk -o NAME,SIZE,MODEL,SERIAL
   ```

   Use the model and serial to distinguish the drives. The example uses `/dev/sdX` for the data drive and `/dev/sdY` for parity; replace these with the correct devices on your server.

2. Partition and format each drive as ext4. **These commands erase the selected drives. Check the device names and serial numbers again before running them.**

   ```bash
   sudo parted /dev/sdX --script mklabel gpt mkpart primary ext4 1MiB 100%
   sudo mkfs.ext4 -L disk1 /dev/sdX1

   sudo parted /dev/sdY --script mklabel gpt mkpart primary ext4 1MiB 100%
   sudo mkfs.ext4 -L parity1 /dev/sdY1
   ```

3. Add label-based mounts to `/etc/fstab`. Create the mount points and use `nofail` so the server can still boot if the USB enclosure is disconnected:

   ```bash
   sudo mkdir -p /mnt/disk1 /mnt/parity1 /srv/media
   sudo nano /etc/fstab
   ```

   Add these lines:

   ```fstab
   LABEL=disk1 /mnt/disk1 ext4 defaults,nofail 0 2
   LABEL=parity1 /mnt/parity1 ext4 defaults,nofail 0 2
   ```

   Save, then mount and check the drives:

   ```bash
   sudo mount -a
   findmnt --target /mnt/disk1
   findmnt --target /mnt/parity1
   ```

4. Install SnapRAID and mergerfs:

   ```bash
   apt-cache policy snapraid mergerfs
   sudo apt update
   sudo apt install snapraid mergerfs
   ```

   `apt-cache policy` should show install candidates. If it does not, check that Ubuntu's `universe` repository is enabled.

5. If media already exists under `/srv/media`, copy it to the data disk before adding and mounting the pool. Stop the stack, copy the files, verify the copy, and keep the original directory until the mounted pool is checked:

   ```bash
   sudo mediactl stop
   sudo rsync -aHAX --info=progress2 /srv/media/ /mnt/disk1/
   ```

   After checking the copied files, move the old directory aside and recreate the mount point:

   ```bash
   sudo mv /srv/media /srv/media.before-mergerfs
   sudo mkdir -p /srv/media
   ```

   If you have not installed the stack yet, skip this step.

6. Add the mergerfs pool to `/etc/fstab`:

   ```fstab
   /mnt/disk* /srv/media fuse.mergerfs cache.files=off,dropcacheonclose=true,category.create=mfs,minfreespace=50G,fsname=mergerfs,nofail 0 0
   ```

   The `/mnt/disk*` pattern includes data disks named `disk1`, `disk2`, and so on; it does not include the parity mount. `category.create=mfs` puts new files on the data disk with the most free space. `minfreespace=50G` stops mergerfs from choosing a disk with less than 50 GB free. Mount and check the pool:

   ```bash
   sudo mount -a
   findmnt /srv/media
   df -h /srv/media
   ```

   Because the mounts use `nofail`, check that the pool is mounted after every boot or enclosure disconnect. Do not start the media stack while `/srv/media` is unmounted; apps could otherwise write files to the server's OS drive.

   If you stopped an existing stack, check that the media is visible under `/srv/media` before starting it again:

   ```bash
   sudo mediactl start
   ```

   The installer uses `/srv/media` by default, so no Compose or app changes are needed.

7. Create `/etc/snapraid.conf` with this example:

   ```bash
   sudo mkdir -p /var/snapraid
   sudo nano /etc/snapraid.conf
   ```

   ```conf
   parity /mnt/parity1/snapraid.parity

   content /var/snapraid/snapraid.content
   content /mnt/disk1/snapraid.content

   data d1 /mnt/disk1/

   exclude *.tmp
   exclude /lost+found/
   exclude *.unrecoverable

   # Add this after mounting a second data disk:
   # data d2 /mnt/disk2/
   ```

   Keep content files on separate disks from each other where possible. The example puts one on the OS drive and another on the data disk.

8. Run the first parity sync:

   ```bash
   sudo snapraid sync
   ```

   A first sync for 16 TB drives can take many hours. Wait for it to finish before relying on parity.

9. Schedule a nightly sync and weekly scrub in root's crontab:

   ```bash
   sudo crontab -e
   ```

   Add:

   ```cron
   0 3 * * * /usr/bin/snapraid sync
   0 5 * * 0 /usr/bin/snapraid scrub -p 8 -o 10
   ```

   Sync updates parity for changes. Scrub checks a portion of stored data for silent read errors.

## Add or replace a drive

To add a data drive, format it as ext4 with the label `disk2`, add its `LABEL=disk2` mount at `/mnt/disk2` in `/etc/fstab`, and add `data d2 /mnt/disk2/` to `/etc/snapraid.conf`. Stop the stack before changing mounts. Remount `/srv/media` or reboot; mergerfs will include the new `/mnt/disk*` data disk. Then run:

```bash
sudo snapraid sync
sudo mediactl start
```

To replace a failed data disk, format the replacement with the same label and mount it at the same path. For example, replacing `d1` means mounting the new disk at `/mnt/disk1`. Then rebuild and verify its contents before syncing:

```bash
sudo snapraid fix -d d1
sudo snapraid check -d d1
sudo snapraid sync
```

## What is outside this pool

This example pools `/srv/media`. Frigate recordings under `/srv/recordings` and the Immich database in `./db/immich` on the server's OS SSD are not in the pool. In the UniFi build, UniFi Protect records to the drive in the UDM Pro.

## Moving to TrueNAS later

TrueNAS with ZFS is a better fit for a later dedicated NAS with drives connected to internal SATA or an HBA. TrueNAS guidance advises against USB-attached pool drives, so the D4-320 is not a good enclosure for a TrueNAS pool.

ZFS adds checksums and can repair damaged data when redundancy is available; it also supports snapshots and RAID-Z. To move later, build the NAS, create its pool, and copy the files over the network. Export the media share with NFS and mount it on the EliteDesk at `/srv/media` so the existing `MEDIA_DIR` setting can stay the same. The EliteDesk can keep running the Docker apps.

Unraid is another option if you want to mix drive sizes in a later NAS.
