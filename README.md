# ScanAiRZ

ScanAiRZ is a Flutter barcode scanning app for single scans, batch inventory scans, scan history, CSV export, and PC sync over the local network.

## Features

- Single barcode scan with optional vibration, scan animation, history save, and PC sync.
- Batch scanning with save, remove, and CSV export flows.
- Searchable scan history with date filtering, sharing, CSV export, and clear actions.
- Saved batch list with batch details and export.
- Configurable PC sync settings, appearance, and scan preferences.
- Windows PC companion receiver that can paste scans into the active desktop app.

## Getting Started

Install Flutter, then run:

```sh
flutter pub get
flutter run
```

For Android scanning and sync, the app declares camera, internet, network state, and vibration permissions.

## PC Companion

Build the Windows receiver:

```sh
dart compile exe tools/pc_companion/bin/scanairz_pc.dart -o build/pc/scanairz_pc.exe
```

Run `build/pc/scanairz_pc.exe` on the PC, focus the target inventory/POS field, then scan from the phone. The companion listens on TCP port `8765` and replies to ScanAiRZ device discovery on UDP port `8888`.
