# ScanAiRZ PC Companion with GUI

A graphical user interface version of the PC companion that receives scans from the ScanAiRZ mobile app and forwards them into the active Windows application like a keyboard-wedge barcode scanner.

## Features
- Graphical user interface with connectivity button and indicator
- Universal design that works across platforms
- WiFi, Bluetooth, and USB connectivity support
- Data synchronization between mobile and PC
- Activity logging

## Run
```sh
dart run bin/scanairz_pc_gui.dart
```

Default port: `8765`

Keep the companion window open, focus the target app or field on the PC, then scan from the phone app.

For networking tests without typing into the focused app:
```sh
dart run bin/scanairz_pc_gui.dart --no-type
```

## Network
- Phone and PC must be on the same local network.
- USB tethering can also work when the phone exposes a network connection to the PC.
- The companion replies to ScanAiRZ discovery broadcasts on UDP port `8888`.