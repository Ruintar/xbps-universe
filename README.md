# Universe — Custom XBPS Repository

[![Build Packages](https://github.com/Ruintar/xbps-universe/actions/workflows/build.yaml/badge.svg)](https://github.com/Ruintar/xbps-universe/actions/workflows/build.yaml)

This repository contains custom XBPS packages.

> [!NOTE]
> Packages in this repository are repackaged from official upstream binaries including Brave, Brave Origin (Beta and Nightly channels), Vivaldi and Vivaldi Snapshot. Each package's build template lives in its own dedicated repository, pulled in automatically by this repository's build workflow.

## Installation Instructions

The easiest way is by adding our repository, which includes pre-built binaries. You can do so by creating a new file and specifying the repository URL.

```bash
echo "repository=https://github.com/Ruintar/xbps-universe/releases/latest/download" | sudo tee /etc/xbps.d/universe-xbps-repo.conf
```

Once you've created file above, proceed with installing any packages you want using xbps

```bash
sudo xbps-install -Su
sudo xbps-install brave-beta brave-nightly brave-origin-beta brave-origin-nightly vivaldi-snapshot
```

## License

This project is released under the MIT License. For more details, see the LICENSE file.
