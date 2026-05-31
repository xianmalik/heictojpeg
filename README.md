# HEIC to JPEG

Your iPhone shoots in HEIC. The rest of the world doesn't speak it.

HEIC to JPEG is a free, native macOS app that converts your iPhone photos into JPEGs that open everywhere — no cloud uploads, no subscriptions, no quality loss.

---

## The Problem

Every photo taken on an iPhone since 2017 is saved as a `.heic` file. HEIC is great for storage, but the moment you try to share those photos — attach them to an email, upload them to a website, send them to someone on Windows, or use them in a design tool — you hit a wall. Most software outside of Apple's ecosystem simply doesn't support HEIC.

HEIC to JPEG gets out of your way and fixes that.

---

## What It Does

Drop your HEIC photos onto the app. Pick an output folder. Hit Convert.

That's it. Your photos come out the other side as full-quality JPEGs, with the original colours and detail preserved exactly as your iPhone captured them.

- **Batch conversion** — drop as many photos as you want at once, or drop an entire folder
- **Full quality** — no compression artifacts, no colour shifts, no guessing
- **Stays on your Mac** — nothing leaves your machine, no account required
- **Native and fast** — built specifically for macOS, uses the same hardware your Mac already uses to display your photos

---

## Also Includes a CLI

For anyone who lives in the terminal, a command-line version is included:

```bash
heictojpeg photo.heic
heictojpeg -d ~/Pictures/Vacation -o ~/Desktop/Converted -r
```

---

## Build

**Requirements:** macOS 26, Xcode command line tools

```bash
make app       # build HeicToJpeg.app
make dmg       # build HeicToJpeg-0.1.0-preview.dmg
make run-app   # build and launch
make clean     # remove build artefacts
```

---

## Version

`0.1.0-preview`

---

## License

MIT
