# Getting Movies and Shows onto Jellyfin

This repo covers legal sources only. It has no torrent, indexer or "free streaming site" setup.

## Your own discs (DVD / Blu-ray)
- **[MakeMKV](https://www.makemkv.com/)** copies a disc to an `.mkv` file with no quality loss. Free while it's in beta (Windows, Mac, Linux).
- **[HandBrake](https://handbrake.fr/)** (open source) shrinks those files if you're short on space.
- Used Blu-rays and DVDs are cheap at thrift stores, library sales, and eBay.
- Legal note: some countries (including the US, under the DMCA) restrict breaking disc copy protection even for personal backups. Check your local law.

## Free and legal
- **Over-the-air TV:** add an antenna and an [HDHomeRun](https://www.silicondust.com/) tuner, and Jellyfin's Live TV and DVR will record local channels for free.
- **Public-domain films:** [Internet Archive – Feature Films](https://archive.org/details/feature_films) has thousands of old films you can download.
- **Your own stuff:** home videos, phone photos, and music you've bought as DRM-free downloads (Bandcamp, Qobuz, 7digital).

## Folder layout Jellyfin understands
Put files under the media folder (default `/srv/media`) like this, and Jellyfin will fetch posters and descriptions automatically:

```
/srv/media/
  movies/
    The Matrix (1999)/
      The Matrix (1999).mkv
  tv/
    Breaking Bad (2008)/
      Season 01/
        Breaking Bad S01E01.mkv
  music/
    Artist/Album/01 - Track.flac
  photos/
  home-videos/
```

Full naming rules: [Jellyfin – Movies](https://jellyfin.org/docs/general/server/media/movies) · [Jellyfin – Shows](https://jellyfin.org/docs/general/server/media/shows)

## Copying files to the server
- **From Mac/Linux:** `scp -r "The Matrix (1999)" youruser@SERVER-IP:/srv/media/movies/`
- **From Windows:** use [WinSCP](https://winscp.net/) (drag and drop) and log in with the server's IP, username and password.
- **USB drive:** plug it into the server, then copy with `cp -r /media/youruser/USBNAME/* /srv/media/movies/`.

After copying, Jellyfin picks up new files on its own, or you can go to Dashboard → Libraries → **Scan All Libraries**.
