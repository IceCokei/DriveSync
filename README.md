<h1>
  DriveSync
  <img src="Images/app-icon.png" width="80" align="right" />
</h1>

**A native macOS menu bar app for seamless Google Drive syncing**

DriveSync lets you sync local folders to Google Drive right from your Mac menu bar — lightweight, intuitive, and zero configuration required.

## Highlights

- **Tiny Footprint** — ~80MB total (10x smaller than the official Google Drive app)
- **Multi-Account Support** — Manage multiple Google Drive accounts in one place
- **Native macOS Experience** — Built with SwiftUI, lives quietly in your menu bar
- **Set & Forget** — Auto-sync on customizable intervals (15 min to daily), or sync manually
- **Smart Volume Handling** — Automatically adapts when macOS remounts volumes with different names

## Features

- **Flexible Folder Syncing** — Map any number of local folders to custom paths on Google Drive
- **Real-Time Progress** — Live transfer speeds, file counts, and completion status
- **Auto Updates** — Checks for the latest version on every launch
- **Powered by [rclone](https://rclone.org/)** — Battle-tested sync engine under the hood

## Requirements

- macOS 14.0+
- Google Drive account(s)

## Installation

### Download (Recommended)

Grab the latest release from the [Releases page](https://github.com/IceCokei/DriveSync/releases) and launch it — updates are handled automatically from then on.

### Build from Source

```bash
git clone https://github.com/IceCokei/DriveSync.git
cd DriveSync
open DriveSync.xcodeproj
# Press ⌘R in Xcode to build and run
```

## Quick Start

1. Click the **cloud icon** in your menu bar
2. **Connect** your Google Drive account (OAuth in browser)
3. Open **Settings** → **Add Folder**
4. Pick a local folder, choose an account, set a destination path (or leave blank for root)
5. Hit **Add** — syncing is ready to go

## Usage

| Action | How |
|--------|-----|
| Sync all folders | Click **Sync All** from the menu bar |
| Sync one folder | Click `⌄` next to a folder → **Sync Now** |
| Auto sync | Set an interval in **Settings** (15 min / 30 min / 1 hr / 4 hr / daily) |
| View progress | Shown in real-time in the menu bar dropdown |

## Acknowledgements

This project is forked from [GoogleDriveSync](https://github.com/saihgupr/GoogleDriveSync) by [@saihgupr](https://github.com/saihgupr). Thanks for the original work and for making it open-source!

## License

[GPL v3.0](LICENSE) — free to use, modify, and distribute. Modified versions must remain open source under the same license.

## Support & Feedback

Found a bug or have a feature request? [Open an issue](https://github.com/IceCokei/DriveSync/issues) on GitHub.

If you find this project useful, consider giving it a ⭐!

## Star History

<a href="https://www.star-history.com/#IceCokei/DriveSync&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=IceCokei/DriveSync&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=IceCokei/DriveSync&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=IceCokei/DriveSync&type=date&legend=top-left" />
 </picture>
</a>