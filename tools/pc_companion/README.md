# ScanAiRZ PC Companion

The PC companion receives scans from the ScanAiRZ mobile app and forwards them into the active Windows application like a keyboard-wedge barcode scanner.

## Run

```sh
scanairz_pc.exe
```

Default port: `8765`

Keep the companion window open, focus the target app or field on the PC, then scan from the phone app.

For networking tests without typing into the focused app:

```sh
scanairz_pc.exe --no-type
```

## Network

- Phone and PC must be on the same local network.
- USB tethering can also work when the phone exposes a network connection to the PC.
- The companion replies to ScanAiRZ discovery broadcasts on UDP port `8888`.
