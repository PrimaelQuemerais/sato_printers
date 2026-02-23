# sato_printers_example

Simple Flutter example app for the `sato_printers` SDK.

## What it does

- Discovers Bluetooth and USB printers.
- Connects to a selected printer.
- Lets the user upload an image from gallery.
- Converts the image to ZPL (`^GFA`) in Dart.
- Sends the generated ZPL to the printer as raw bytes.

## Run

```bash
cd example
flutter pub get
flutter run
```

## Flow inside the app

1. Tap `Discover Printers`.
2. Select a printer and tap `Connect`.
3. Tap `Upload Image`.
4. (Optional) tweak compression and blackness, then rebuild ZPL.
5. Tap `Send ZPL to Printer`.
